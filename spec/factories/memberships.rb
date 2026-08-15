FactoryBot.define do
  factory :membership do
    organization
    user
    active { true }
  end
end
