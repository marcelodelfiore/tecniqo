FactoryBot.define do
  factory :evidence do
    transient do
      upload_content { "immutable field evidence\n" }
    end

    organization { execution.organization }
    uploaded_by_membership do
      execution.participant_memberships.first || association(:membership, organization: organization)
    end
    execution
    evidence_type { "technical_file" }
    original_filename { "evidence.txt" }
    content_type { "text/plain" }
    byte_size { upload_content.bytesize }
    integrity_algorithm { "SHA-256" }
    integrity_digest { Digest::SHA256.hexdigest(upload_content) }
    accepted_at { Time.current }

    after(:build) do |evidence, evaluator|
      evidence.original.attach(io: StringIO.new(evaluator.upload_content), filename: evidence.original_filename,
                               content_type: evidence.content_type)
    end

    before(:create) do |evidence|
      create(:membership_role, membership: evidence.uploaded_by_membership, role: "technician") unless
        evidence.uploaded_by_membership.membership_roles.exists?(role: "technician")
      unless evidence.execution.participant?(evidence.uploaded_by_membership)
        create(:execution_participant, organization: evidence.organization, execution: evidence.execution,
                                       membership: evidence.uploaded_by_membership)
      end
    end
  end
end
