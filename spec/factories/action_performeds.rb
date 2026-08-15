FactoryBot.define do
  factory :action_performed do
    organization { execution.organization }
    execution
    recorded_by_membership { association :membership, organization: organization }
    recorded_at { Time.current }
    description { "Damaged terminal replaced and connection retorqued." }

    before(:create) { |record| prepare_technical_record_actor(record) }
  end
end
