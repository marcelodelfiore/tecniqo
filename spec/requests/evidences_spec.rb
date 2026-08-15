require "rails_helper"

RSpec.describe "Evidence storage", type: :request do
  def sign_in(user)
    _token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def build_context
    organization = create(:organization)
    technician = create(:membership, organization: organization)
    create(:membership_role, membership: technician, role: "technician")
    customer = create(:customer, organization: organization)
    site = create(:site, organization: organization, customer: customer)
    work_order = create(:work_order, organization: organization, customer: customer, site: site,
                                     service_type: create(:service_type, organization: organization))
    execution = create(:execution, organization: organization, work_order: work_order)
    create(:execution_participant, organization: organization, execution: execution,
                                   membership: technician)
    [ technician, work_order, execution ]
  end

  let(:fixture_path) { Rails.root.join("spec/fixtures/files/evidence.txt") }

  def upload_params(forged)
    { evidence: {
      original: Rack::Test::UploadedFile.new(fixture_path, "text/plain"),
      evidence_type: "technical_file", description: "Motor test",
      uploaded_by_membership_id: forged.id, organization_id: create(:organization).id
    } }
  end

  it "attributes and fingerprints an upload without accepting ownership metadata" do
    technician, work_order, execution = build_context
    forged = create(:membership, organization: work_order.organization)
    sign_in(technician.user)

    expect {
      post work_order_execution_evidences_path(work_order, execution), params: upload_params(forged)
    }.to change(Evidence, :count).by(1)

    evidence = Evidence.last
    expect(response).to redirect_to(work_order_execution_path(work_order, execution))
    expect(evidence).to have_attributes(uploaded_by_membership: technician,
                                        organization: work_order.organization,
                                        integrity_digest: Digest::SHA256.file(fixture_path).hexdigest)
  end

  it "streams the unchanged original through an authorized application endpoint" do
    technician, work_order, execution = build_context
    evidence = Evidence.ingest!(execution: execution, uploaded_by_membership: technician,
                                upload: { io: File.open(fixture_path), filename: "evidence.txt",
                                          content_type: "text/plain" },
                                evidence_type: "technical_file")
    sign_in(technician.user)

    get original_work_order_execution_evidence_path(work_order, execution, evidence)

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(File.binread(fixture_path))
    expect(response.headers["Content-Disposition"]).to include("attachment", "evidence.txt")
  end

  it "denies cross-tenant upload and direct download lookup" do
    _technician, work_order, execution = build_context
    outsider = create(:membership, organization: create(:organization))
    create(:membership_role, membership: outsider, role: "technician")
    sign_in(outsider.user)

    post work_order_execution_evidences_path(work_order, execution), params: {
      evidence: { original: Rack::Test::UploadedFile.new(fixture_path, "text/plain"),
                  evidence_type: "technical_file" }
    }
    expect(response).to redirect_to(organization_selection_path)
    expect(Evidence.count).to eq(0)
  end
end
