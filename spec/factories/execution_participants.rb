FactoryBot.define do
  factory :execution_participant do
    organization { execution.organization }
    execution
    membership do
      association(:membership, organization: organization).tap do |candidate|
        candidate.membership_roles << build(:membership_role, membership: candidate, role: "technician")
      end
    end
    added_by { association :user }
  end
end
