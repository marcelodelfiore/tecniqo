FactoryBot.define do
  factory :customer do
    organization
    sequence(:name) { |number| "Customer #{number}" }
  end
end
