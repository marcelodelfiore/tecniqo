require "rails_helper"

RSpec.describe "Engineering review workflow", type: :request do
  def sign_in(user)
    _token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def member(role, organization:, email: nil)
    membership = create(:membership, organization: organization,
                                     user: create(:user, email: email || "phase6-#{SecureRandom.hex(6)}@example.com"))
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def submit_visit(execution, technician, outcome:)
    execution.update_columns(outcome: outcome, outcome_recorded_at: Time.current,
                             outcome_recorded_by_membership_id: technician.id,
                             outcome_reason: outcome == "return_required" ? "material_required" : nil)
    create(:execution_event, execution: execution, organization: execution.organization,
                             actor_membership: technician, event_type: "submitted")
  end

  def build_story
    organization = create(:organization)
    supervisor = member("supervisor", organization: organization)
    technician = member("technician", organization: organization, email: "joao@example.com")
    engineer = member("engineer", organization: organization, email: "maria@example.com")
    customer = create(:customer, organization: organization, name: "Indústria ABC")
    site = create(:site, organization: organization, customer: customer, name: "Betim Plant")
    asset = create(:asset, organization: organization, site: site, name: "Motor M-21")
    work_order = create(:work_order, organization: organization, customer: customer, site: site,
                                     asset: asset,
                                     service_type: create(:service_type, organization: organization,
                                                                                name: "Corrective Electrical Maintenance"))
    first = create(:execution, organization: organization, work_order: work_order, visit_number: 1)
    second = create(:execution, organization: organization, work_order: work_order, visit_number: 2)
    [ first, second ].each do |execution|
      create(:execution_participant, organization: organization, execution: execution,
                                     membership: technician)
    end
    finding = create(:finding, execution: first, organization: organization,
                               recorded_by_membership: technician,
                               description: "Abnormal heating at terminal T2")
    measurement = create(:measurement, execution: second, organization: organization,
                                       recorded_by_membership: technician, quantity: "temperature",
                                       value: 87.3, unit: "degC", measurement_point: "Terminal T2")
    create(:action_performed, execution: second, organization: organization,
                              recorded_by_membership: technician,
                              description: "Contactor CWM65 replaced.")
    create(:material_used, execution: second, organization: organization,
                           recorded_by_membership: technician, description: "Contactor CWM65")
    create(:recommendation, execution: first, organization: organization,
                            recorded_by_membership: technician,
                            description: "Replace contactor before continuous operation.")
    evidence = create(:evidence, execution: first, organization: organization,
                                 uploaded_by_membership: technician)
    finding.sync_evidence_ids!([ evidence.id ])
    submit_visit(first, technician, outcome: "return_required")
    submit_visit(second, technician, outcome: "completed")
    review = EngineeringReview.create_for_ready_work_order!(work_order)
    [ supervisor, technician, engineer, work_order, first, second, measurement, review ]
  end

  def start_review_and_assert_story(engineer, work_order, review)
    sign_in(engineer.user)
    get engineering_reviews_path
    expect(response.body).to include(work_order.public_identifier, "Indústria ABC", "2 visits")
    post start_engineering_review_path(review)
    get engineering_review_path(review)
    expect(response.body).to include("Visit 1", "Visit 2", "Abnormal heating at terminal T2",
                                     "87.3", "Contactor CWM65", "Replace contactor", "SHA-256")
  end

  def request_clarification(review, execution, measurement, technician)
    get new_engineering_review_clarification_request_path(
      review, execution_id: execution.id, target_type: "Measurement", target_id: measurement.id
    )
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("87.3", "Terminal T2", technician.user.email)
    post engineering_review_clarification_requests_path(
      review, execution_id: execution.id, target_type: "Measurement", target_id: measurement.id
    ), params: { clarification_request: {
      question: "Was this measurement taken under normal operating load?",
      recipient_membership_id: technician.id
    } }
    ClarificationRequest.last
  end

  def technician_responds(technician, work_order, clarification)
    delete session_path
    sign_in(technician.user)
    get my_work_index_path
    expect(response.body).to include("Needs information", work_order.public_identifier,
                                     "Was this measurement taken under normal operating load?")
    post clarification_request_evidences_path(clarification), params: { evidence: {
      evidence_type: "technical_file", original: fixture_file_upload("evidence.txt", "text/plain"),
      description: "Clamp meter reading under normal load"
    } }
    evidence = clarification.evidences.last
    patch clarification_request_path(clarification), params: { clarification_request: {
      response: "Yes. Motor had been operating under normal process load for approximately 20 minutes.",
      evidence_ids: [ evidence.id ]
    } }
    evidence
  end

  def engineer_resolves_and_approves(engineer, review, clarification, evidence)
    delete session_path
    sign_in(engineer.user)
    get engineering_review_path(review)
    expect(response.body).to include("Response received", "normal process load", evidence.original_filename)
    post resolve_clarification_request_path(clarification)
    post approve_engineering_review_path(review)
    expect(review.reload).to have_attributes(state: "approved", approved_by: engineer.user)
    expect(review.approved_at).to be_present
  end

  it "runs the canonical multi-visit clarification and approval flow" do
    _supervisor, technician, engineer, work_order, _first, second, measurement, review = build_story
    start_review_and_assert_story(engineer, work_order, review)
    clarification = request_clarification(review, second, measurement, technician)
    expect(review.reload.state).to eq("changes_requested")
    response_evidence = technician_responds(technician, work_order, clarification)
    expect(clarification.reload).to have_attributes(state: "responded",
                                                     responded_by_membership: technician)
    engineer_resolves_and_approves(engineer, review, clarification, response_evidence)
  end

  def assert_supervisor_cannot_claim(supervisor, review)
    sign_in(supervisor.user)
    post start_engineering_review_path(review)
    expect(review.reload.state).to eq("pending")
  end

  def create_open_clarification(engineer, review, execution, measurement, technician)
    delete session_path
    sign_in(engineer.user)
    post start_engineering_review_path(review)
    clarification = request_clarification(review, execution, measurement, technician)
    post approve_engineering_review_path(review)
    expect(review.reload.state).to eq("changes_requested")
    clarification
  end

  def assert_unrelated_technician_cannot_respond(clarification)
    delete session_path
    unrelated = member("technician", organization: clarification.organization)
    sign_in(unrelated.user)
    patch clarification_request_path(clarification), params: {
      clarification_request: { response: "Forged response." }
    }
    expect(clarification.reload.state).to eq("requested")
  end

  def assert_cross_tenant_denial(review, clarification)
    delete session_path
    outsider = member("engineer", organization: create(:organization))
    sign_in(outsider.user)
    get engineering_review_path(review)
    expect(response).to redirect_to(organization_selection_path)
    get clarification_request_path(clarification)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "enforces technical-role, recipient, approval, and tenant boundaries" do
    supervisor, technician, engineer, _work_order, _first, second, measurement, review = build_story
    assert_supervisor_cannot_claim(supervisor, review)
    clarification = create_open_clarification(engineer, review, second, measurement, technician)
    assert_unrelated_technician_cannot_respond(clarification)
    assert_cross_tenant_denial(review, clarification)
  end
end
