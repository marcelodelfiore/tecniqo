FactoryBot.define do
  factory :organization do
    sequence(:name) { |number| "Organization #{number}" }
  end
end
