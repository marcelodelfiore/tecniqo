require "rails_helper"

RSpec.describe Evidence do
  def execution_context
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
    [ execution, technician ]
  end

  def upload(content = "immutable field evidence\n", filename: "evidence.txt", type: "text/plain")
    { io: StringIO.new(content), filename: filename, content_type: type }
  end

  it "preserves original metadata and fingerprints exact uploaded bytes with SHA-256" do
    execution, technician = execution_context

    evidence = described_class.ingest!(execution: execution, uploaded_by_membership: technician,
                                       upload: upload, evidence_type: "technical_file")

    expect(evidence).to have_attributes(organization: execution.organization,
                                        uploaded_by_membership: technician,
                                        original_filename: "evidence.txt", content_type: "text/plain",
                                        byte_size: 25, integrity_algorithm: "SHA-256",
                                        integrity_digest: Digest::SHA256.hexdigest("immutable field evidence\n"))
    expect(evidence.original.download).to eq("immutable field evidence\n")
  end

  it "produces stable fingerprints and changes them when the bytes change" do
    first_execution, first_technician = execution_context
    second_execution, second_technician = execution_context
    third_execution, third_technician = execution_context

    first = described_class.ingest!(execution: first_execution, uploaded_by_membership: first_technician,
                                    upload: upload("same"), evidence_type: "technical_file")
    second = described_class.ingest!(execution: second_execution, uploaded_by_membership: second_technician,
                                     upload: upload("same"), evidence_type: "technical_file")
    third = described_class.ingest!(execution: third_execution, uploaded_by_membership: third_technician,
                                    upload: upload("different"), evidence_type: "technical_file")

    expect(first.integrity_digest).to eq(second.integrity_digest)
    expect(first.integrity_digest).not_to eq(third.integrity_digest)
  end

  it "rejects an uploader from another tenant or outside the participant list" do
    execution, = execution_context
    outsider = create(:membership, organization: create(:organization))
    create(:membership_role, membership: outsider, role: "technician")

    expect {
      described_class.ingest!(execution: execution, uploaded_by_membership: outsider,
                              upload: upload, evidence_type: "technical_file")
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "rejects unsupported media and oversized originals" do
    execution, technician = execution_context
    evidence = build(:evidence, execution: execution, uploaded_by_membership: technician,
                                evidence_type: "document", content_type: "application/x-msdownload")
    evidence.byte_size = Evidence::MAX_BYTES.fetch("document") + 1

    expect(evidence).not_to be_valid
    expect(evidence.errors).to include(:content_type, :byte_size)
  end

  it "prevents metadata changes, original replacement, and deletion after acceptance" do
    execution, technician = execution_context
    evidence = described_class.ingest!(execution: execution, uploaded_by_membership: technician,
                                       upload: upload, evidence_type: "technical_file")

    expect { evidence.update!(description: "rewritten") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect { evidence.original.attach(upload("replacement")) }
      .to raise_error(Evidence::ImmutableOriginalError)
    expect(evidence.destroy).to be(false)
    expect(evidence.reload.original.download).to eq("immutable field evidence\n")
  end
end
