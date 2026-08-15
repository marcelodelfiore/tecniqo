FactoryBot.define do
  factory :material_used do
    organization { execution.organization }
    execution
    recorded_by_membership { association :membership, organization: organization }
    recorded_at { Time.current }
    description { "Replacement terminal" }
    quantity { 1 }
    unit { "piece" }

    before(:create) { |record| prepare_technical_record_actor(record) }
  end
end
