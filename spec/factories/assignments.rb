FactoryBot.define do
  factory :assignment do
    organization { work_order.organization }
    work_order
    membership do
      association(:membership, organization: organization).tap do |candidate|
        candidate.membership_roles << build(:membership_role, membership: candidate, role: "technician")
      end
    end
    assigned_by { association :user }
    assigned_at { Time.current }
  end
end
