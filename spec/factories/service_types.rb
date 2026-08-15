FactoryBot.define do
  factory :service_type do
    organization
    sequence(:name) { |number| "Service Type #{number}" }
    active { true }
  end
end
