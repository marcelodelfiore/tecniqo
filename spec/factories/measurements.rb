FactoryBot.define do
  factory :measurement do
    organization { execution.organization }
    execution
    recorded_by_membership { association :membership, organization: organization }
    recorded_at { Time.current }
    quantity { "temperature" }
    value { 87.3 }
    unit { "degC" }
    measurement_point { "Contactor terminal T2" }

    before(:create) { |record| prepare_technical_record_actor(record) }
  end
end
