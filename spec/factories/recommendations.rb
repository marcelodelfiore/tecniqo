FactoryBot.define do
  factory :recommendation do
    organization { execution.organization }
    execution
    recorded_by_membership { association :membership, organization: organization }
    recorded_at { Time.current }
    description { "Reinspect connection during next scheduled shutdown." }

    before(:create) { |record| prepare_technical_record_actor(record) }
  end
end
