FactoryBot.define do
  factory :membership_role do
    membership
    role { "technician" }
  end
end
