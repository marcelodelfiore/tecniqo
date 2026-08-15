require "rails_helper"

RSpec.describe "Field executions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def sign_in(user)
    _token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def member(role, organization:, email: nil)
    membership = create(:membership, organization: organization,
                                     user: create(:user, email: email || unique_email))
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def unique_email
    "phase4-#{SecureRandom.hex(6)}@example.com"
  end

  def perform_timeline(work_order, execution)
    actions = [
      [ [ 7, 58 ], work_order_execution_arrive_path(work_order, execution), {} ],
      [ [ 9, 47 ], work_order_execution_start_work_path(work_order, execution), {} ],
      [ [ 10, 31 ], work_order_execution_pause_path(work_order, execution), { reason: "customer_request" } ],
      [ [ 11, 16 ], work_order_execution_resume_path(work_order, execution), {} ]
    ]
    actions.each do |(hour, minute), path, params|
      travel_to(Time.zone.local(2026, 8, 18, hour, minute)) { post path, params: params }
    end
    travel_to Time.zone.local(2026, 8, 18, 12, 2) do
      post work_order_execution_finish_work_path(work_order, execution),
           params: { outcome: "return_required", outcome_reason: "material_required",
                     outcome_note: "Contactor WEG CWM65 required." }
    end
    travel_to(Time.zone.local(2026, 8, 18, 12, 17)) do
      post work_order_execution_leave_path(work_order, execution)
    end
    travel_to(Time.zone.local(2026, 8, 18, 12, 20)) do
      post work_order_execution_submit_path(work_order, execution)
    end
  end

  def build_context
    organization = create(:organization)
    supervisor = member("supervisor", organization: organization)
    technician = member("technician", organization: organization, email: "joao@example.com")
    customer = create(:customer, organization: organization)
    site = create(:site, customer: customer)
    work_order = create(:work_order, organization: organization, customer: customer, site: site,
                                     service_type: create(:service_type, organization: organization))
    work_order.assign_to!(technician, assigned_by: supervisor.user)
    [ supervisor, technician, work_order ]
  end

  def create_visit(supervisor, work_order)
    sign_in(supervisor.user)
    post work_order_executions_path(work_order), params: { execution: { scheduled_start: "2026-08-18T08:00" } }
    Execution.last
  end

  it "runs the field timeline with server actor/time and exposes it in My Work" do
    supervisor, technician, work_order = build_context
    execution = create_visit(supervisor, work_order)
    expect(execution.participant_memberships).to contain_exactly(technician)
    delete session_path
    sign_in(technician.user)
    get my_work_index_path
    expect(response.body).to include(work_order.public_identifier, "Visit 1")
    perform_timeline(work_order, execution)
    expect(execution.reload.current_state).to eq("submitted")
    expect(execution.execution_events.reorder(nil).distinct.pluck(:actor_membership_id)).to eq([ technician.id ])
    expect(execution.site_presence_duration).to eq(4.hours + 19.minutes)
  end

  it "creates a scheduled return visit under the same Work Order" do
    supervisor, technician, work_order = build_context
    execution = create_visit(supervisor, work_order)
    delete session_path
    sign_in(technician.user)
    perform_timeline(work_order, execution)
    delete session_path
    sign_in(supervisor.user)
    post work_order_executions_path(work_order), params: { execution: { scheduled_start: "2026-08-20T13:00" } }

    expect(response).to redirect_to(work_order_execution_path(work_order, 2))
    expect(work_order.executions.order(:visit_number).pluck(:visit_number)).to eq([ 1, 2 ])
    expect(execution.execution_events.count).to eq(7)
  end

  it "rejects double actions without duplicating events" do
    _supervisor, technician, work_order = build_context
    execution = Execution.create_for!(work_order: work_order, created_by: work_order.created_by)
    sign_in(technician.user)

    2.times { post work_order_execution_arrive_path(work_order, execution) }

    expect(execution.execution_events.where(event_type: "arrived_at_site").count).to eq(1)
    expect(response).to redirect_to(work_order_execution_path(work_order, execution))
  end

  it "supports the unable-to-execute path" do
    _supervisor, technician, work_order = build_context
    execution = Execution.create_for!(work_order: work_order, created_by: work_order.created_by)
    sign_in(technician.user)

    post work_order_execution_arrive_path(work_order, execution)
    post work_order_execution_unable_path(work_order, execution),
         params: { outcome_reason: "access_denied", outcome_note: "Security denied access." }
    post work_order_execution_leave_path(work_order, execution)
    post work_order_execution_submit_path(work_order, execution)

    expect(execution.reload).to have_attributes(outcome: "unable_to_execute", current_state: "submitted")
    expect(execution.execution_events.pluck(:event_type)).to eq(%w[arrived_at_site left_site submitted])
  end

  it "allows participant history to preserve Work Order access after reassignment" do
    supervisor, technician, work_order = build_context
    execution = Execution.create_for!(work_order: work_order, created_by: supervisor.user)
    replacement = member("technician", organization: work_order.organization)
    work_order.assign_to!(replacement, assigned_by: supervisor.user)
    sign_in(technician.user)

    get work_order_path(work_order)
    expect(response).to have_http_status(:ok)
    get work_order_execution_path(work_order, execution)
    expect(response).to have_http_status(:ok)
  end

  it "lets a Supervisor add only eligible same-tenant participants" do
    supervisor, _technician, work_order = build_context
    execution = Execution.create_for!(work_order: work_order, created_by: supervisor.user)
    additional = member("technician", organization: work_order.organization)
    foreign = member("technician", organization: create(:organization))
    sign_in(supervisor.user)

    post work_order_execution_participants_path(work_order, execution), params: { membership_id: additional.id }
    expect(execution.participant_memberships.reload).to include(additional)

    expect {
      post work_order_execution_participants_path(work_order, execution), params: { membership_id: foreign.id }
    }.not_to change(ExecutionParticipant, :count)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "denies unrelated and cross-tenant Technicians" do
    _supervisor, _technician, work_order = build_context
    execution = Execution.create_for!(work_order: work_order, created_by: work_order.created_by)
    foreign = member("technician", organization: create(:organization))
    sign_in(foreign.user)

    get work_order_execution_path(work_order, execution)
    expect(response).to redirect_to(organization_selection_path)
    post work_order_execution_arrive_path(work_order, execution)
    expect(response).to redirect_to(organization_selection_path)
    expect(execution.execution_events).to be_empty
  end
end
