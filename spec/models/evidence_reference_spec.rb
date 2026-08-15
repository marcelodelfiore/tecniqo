require "rails_helper"

RSpec.describe EvidenceReference do
  it "lets one immutable Evidence support multiple technical facts without duplicating its blob" do
    finding = create(:finding)
    measurement = create(:measurement, execution: finding.execution,
                                       organization: finding.organization,
                                       recorded_by_membership: finding.recorded_by_membership)
    evidence = create(:evidence, execution: finding.execution,
                                 organization: finding.organization,
                                 uploaded_by_membership: finding.recorded_by_membership)
    digest = evidence.integrity_digest
    blob_id = evidence.original.blob.id

    finding.sync_evidence_ids!([ evidence.id ])
    measurement.sync_evidence_ids!([ evidence.id ])

    expect(evidence.evidence_references.count).to eq(2)
    expect(evidence.reload).to have_attributes(integrity_digest: digest)
    expect(evidence.original.blob.id).to eq(blob_id)
  end

  it "rejects technical records and Evidence from another Execution" do
    finding = create(:finding)
    foreign_evidence = create(:evidence)
    reference = build(:evidence_reference, technical_record: finding,
                                           execution: finding.execution,
                                           organization: finding.organization,
                                           evidence: foreign_evidence)

    expect(reference).not_to be_valid
    expect(reference.errors).to include(:evidence)
    expect { finding.sync_evidence_ids!([ foreign_evidence.id ]) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it "enforces the Evidence Execution and tenant boundary in PostgreSQL" do
    reference = create(:evidence_reference)
    foreign_evidence = create(:evidence)

    expect {
      described_class.where(id: reference.id).update_all(evidence_id: foreign_evidence.id)
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "unlinks before submission without deleting Evidence and locks links after submission" do
    reference = create(:evidence_reference)
    evidence = reference.evidence
    reference.destroy!
    expect(evidence.reload).to be_persisted

    replacement = create(:evidence_reference, technical_record: reference.technical_record,
                                               execution: reference.execution,
                                               organization: reference.organization,
                                               evidence: evidence)
    create(:execution_event, execution: replacement.execution,
                             organization: replacement.organization,
                             actor_membership: replacement.technical_record.recorded_by_membership,
                             event_type: "submitted")
    expect(replacement.destroy).to be(false)
  end
end
