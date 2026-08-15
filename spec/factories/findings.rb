FactoryBot.define do
  factory :finding do
    organization { execution.organization }
    execution
    recorded_by_membership { association :membership, organization: organization }
    recorded_at { Time.current }
    description { "Abnormal heating observed at contactor terminal T2." }
    severity { "significant" }

    before(:create) { |record| prepare_technical_record_actor(record) }
  end
end
