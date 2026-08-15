require "rails_helper"

RSpec.describe "Service Type, Work Order, and Assignment management", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def member(role, organization: create(:organization), email: nil)
    membership = create(:membership, organization: organization,
                                     user: email ? create(:user, email: email) : create(:user))
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def context_for(organization)
    customer = create(:customer, organization: organization, name: "Indústria ABC")
    site = create(:site, customer: customer, name: "Betim Plant")
    asset = create(:asset, site: site, name: "Motor M-21")
    service_type = create(:service_type, organization: organization,
                                         name: "Corrective Electrical Maintenance")
    [ customer, site, asset, service_type ]
  end

  def post_work_order(customer:, site:, asset:, service_type:, technician:, requested_work:)
    post work_orders_path, params: { work_order: {
      customer_id: customer.id, site_id: site.id, asset_id: asset&.id,
      service_type_id: service_type.id, requested_work: requested_work,
      priority: "high", scheduled_start: "2026-08-18T08:00",
      technician_membership_id: technician&.id
    } }
  end

  def expect_work_order_denied(work_order)
    get work_order_path(work_order)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "lets a Supervisor manage Service Types" do
    supervisor = member("supervisor")
    sign_in(supervisor.user)

    post service_types_path, params: { service_type: { name: "Thermographic Inspection" } }
    service_type = ServiceType.last
    expect(response).to redirect_to(service_types_path)
    expect(service_type.organization).to eq(supervisor.organization)

    patch deactivate_service_type_path(service_type)
    expect(service_type.reload).not_to be_active
  end

  it "creates, schedules, and assigns a contextual Work Order", :aggregate_failures do
    supervisor = member("supervisor")
    technician = member("technician", organization: supervisor.organization, email: "joao@example.com")
    customer, site, asset, service_type = context_for(supervisor.organization)
    sign_in(supervisor.user)

    post_work_order(customer: customer, site: site, asset: asset, service_type: service_type,
                    technician: technician, requested_work: "Motor protection trips after several minutes.")
    work_order = WorkOrder.last

    expect(response).to redirect_to(work_order_path(work_order))
    expect(work_order.public_identifier).to match(/\AOS-\d{4}-\d{6}\z/)
    expect(work_order).to have_attributes(customer: customer, site: site, asset: asset,
                                          service_type: service_type, priority: "high")
    expect(work_order.current_assignment.membership).to eq(technician)
  end

  it "prefills Customer, Site, and Asset from contextual creation" do
    supervisor = member("supervisor")
    customer, site, asset, = context_for(supervisor.organization)
    sign_in(supervisor.user)

    get new_work_order_path(customer_id: customer.id, site_id: site.id, asset_id: asset.id)

    expect(response).to have_http_status(:ok)
    page = response.parsed_body
    expect(page.at_css("#work_order_customer_id option[selected]")["value"]).to eq(customer.id.to_s)
    expect(page.at_css("#work_order_site_id option[selected]")["value"]).to eq(site.id.to_s)
    expect(page.at_css("#work_order_asset_id option[selected]")["value"]).to eq(asset.id.to_s)
    expect(response.body).to include("data-controller=\"dependent-selects\"")
  end

  it "preserves assignment history when a Supervisor reassigns" do
    supervisor = member("supervisor")
    first = member("technician", organization: supervisor.organization, email: "joao@example.com")
    second = member("technician", organization: supervisor.organization, email: "carlos@example.com")
    customer, site, _asset, service_type = context_for(supervisor.organization)
    work_order = create(:work_order, organization: supervisor.organization, customer: customer,
                                     site: site, service_type: service_type)
    work_order.assign_to!(first, assigned_by: supervisor.user)
    sign_in(supervisor.user)

    post work_order_assignment_path(work_order), params: { membership_id: second.id }

    expect(response).to redirect_to(work_order_path(work_order))
    expect(work_order.reload.current_assignment.membership).to eq(second)
    expect(work_order.assignments.where(membership: first).pick(:ended_at)).to be_present
  end

  it "allows a Technician to see only their currently assigned Work Order" do
    technician = member("technician")
    customer, site, _asset, service_type = context_for(technician.organization)
    assigned = create(:work_order, organization: technician.organization, customer: customer,
                                   site: site, service_type: service_type)
    hidden = create(:work_order, organization: technician.organization, customer: customer,
                                 site: site, service_type: service_type)
    assigned.assign_to!(technician, assigned_by: create(:user))
    sign_in(technician.user)

    get work_orders_path
    expect(response.body).to include(assigned.public_identifier)
    expect(response.body).not_to include(hidden.public_identifier)

    get work_order_path(hidden)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "rejects cross-tenant context and assignees" do
    supervisor = member("supervisor")
    customer, site, _asset, service_type = context_for(supervisor.organization)
    foreign_customer, foreign_site, foreign_asset, foreign_service_type = context_for(create(:organization))
    foreign_technician = member("technician", organization: foreign_customer.organization)
    sign_in(supervisor.user)

    expect {
      post_work_order(customer: customer, site: foreign_site, asset: foreign_asset,
                      service_type: foreign_service_type, technician: foreign_technician,
                      requested_work: "Invalid context")
    }.not_to change(WorkOrder, :count)
    expect(response).to redirect_to(organization_selection_path)

    foreign_work_order = create(:work_order, organization: foreign_customer.organization,
                                             customer: foreign_customer, site: foreign_site,
                                             service_type: foreign_service_type)
    expect_work_order_denied(foreign_work_order)
  end
end
