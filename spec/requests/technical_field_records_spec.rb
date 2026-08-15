require "rails_helper"

RSpec.describe "Technical field records", type: :request do
  def sign_in(user)
    _token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def build_context
    organization = create(:organization)
    technician = member("technician", organization: organization)
    engineer = member("engineer", organization: organization)
    customer = create(:customer, organization: organization, name: "Indústria ABC")
    site = create(:site, organization: organization, customer: customer, name: "Betim Plant")
    asset = create(:asset, organization: organization, site: site, name: "Motor M-21")
    work_order = create(:work_order, organization: organization, customer: customer, site: site,
                                     asset: asset,
                                     service_type: create(:service_type, organization: organization))
    execution = create(:execution, organization: organization, work_order: work_order)
    create(:execution_participant, organization: organization, execution: execution,
                                   membership: technician)
    evidence = create(:evidence, organization: organization, execution: execution,
                                 uploaded_by_membership: technician)
    [ technician, engineer, work_order, execution, evidence ]
  end

  def capture_canonical_record(work_order, execution, evidence, forged)
    post work_order_execution_findings_path(work_order, execution), params: {
      finding: { description: "Abnormal heating observed at contactor terminal T2.",
                 severity: "significant", evidence_ids: [ evidence.id ],
                 organization_id: create(:organization).id, recorded_by_membership_id: forged.id }
    }
    post work_order_execution_measurements_path(work_order, execution), params: {
      measurement: { quantity: "temperature", value: "87.3", unit: "degC",
                     measurement_point: "Terminal T2", evidence_ids: [ evidence.id ] }
    }
    post work_order_execution_action_performeds_path(work_order, execution), params: {
      action_performed: { description: "Damaged terminal replaced and connection retorqued.",
                          evidence_ids: [ evidence.id ] }
    }
    post work_order_execution_materials_used_index_path(work_order, execution), params: {
      material_used: { description: "Replacement terminal", quantity: "1", unit: "piece" }
    }
    post work_order_execution_recommendations_path(work_order, execution), params: {
      recommendation: { description: "Reinspect connection during next scheduled shutdown." }
    }
  end

  def create_engineer_story(technician, execution, evidence)
    attributes = { execution: execution, organization: execution.organization,
                   recorded_by_membership: technician }
    finding = create(:finding, **attributes, description: "Abnormal heating at terminal T2")
    measurement = create(:measurement, **attributes, quantity: "temperature", value: "87.3",
                                         unit: "degC", measurement_point: "Terminal T2")
    finding.sync_evidence_ids!([ evidence.id ])
    measurement.sync_evidence_ids!([ evidence.id ])
    create(:action_performed, **attributes)
    create(:material_used, **attributes)
    create(:recommendation, **attributes)
    create(:execution_event, execution: execution, organization: execution.organization,
                             actor_membership: technician, event_type: "submitted")
  end

  it "captures the canonical structured record with server context and shared Evidence" do
    technician, _engineer, work_order, execution, evidence = build_context
    forged = create(:membership, organization: work_order.organization)
    sign_in(technician.user)

    capture_canonical_record(work_order, execution, evidence, forged)

    expect(Finding.last).to have_attributes(organization: work_order.organization,
                                             recorded_by_membership: technician)
    expect(evidence.evidence_references.pluck(:technical_record_type)).to contain_exactly(
      "Finding", "Measurement", "ActionPerformed"
    )
    expect(response).to redirect_to(work_order_execution_path(work_order, execution))
  end

  it "preserves entered values and explains incompatible measurement units" do
    technician, _engineer, work_order, execution, = build_context
    sign_in(technician.user)

    post work_order_execution_measurements_path(work_order, execution), params: {
      measurement: { quantity: "voltage", value: "397", unit: "degC",
                     measurement_point: "L1-L2" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("397", "L1-L2", "cannot be used for Voltage")
    expect(Measurement.count).to eq(0)
  end

  it "presents the submitted evidence-backed technical story to an Engineer" do
    technician, engineer, work_order, execution, evidence = build_context
    create_engineer_story(technician, execution, evidence)
    sign_in(engineer.user)

    get work_order_execution_path(work_order, execution)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Technical record", "Abnormal heating at terminal T2",
                                     "87.3", "°C", "Terminal T2", "Work performed",
                                     "Materials used", "Recommendations", evidence.original_filename)
    expect(response.body).not_to include("+ Finding")
  end

  it "blocks submitted mutation and cross-tenant direct access" do
    technician, _engineer, work_order, execution, = build_context
    finding = create(:finding, execution: execution, organization: execution.organization,
                               recorded_by_membership: technician)
    create(:execution_event, execution: execution, organization: execution.organization,
                             actor_membership: technician, event_type: "submitted")
    sign_in(technician.user)

    patch work_order_execution_finding_path(work_order, execution, finding),
          params: { finding: { description: "Silent rewrite" } }
    expect(response).to redirect_to(organization_selection_path)
    expect(finding.reload.description).not_to eq("Silent rewrite")

    delete session_path
    outsider = member("engineer", organization: create(:organization))
    sign_in(outsider.user)
    get work_order_execution_path(work_order, execution)
    expect(response).to redirect_to(organization_selection_path)
  end
end
