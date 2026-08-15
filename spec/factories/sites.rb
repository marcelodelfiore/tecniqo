FactoryBot.define do
  factory :site do
    organization { customer.organization }
    customer
    sequence(:name) { |number| "Site #{number}" }
  end
end
