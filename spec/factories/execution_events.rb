FactoryBot.define do
  factory :execution_event do
    organization { execution.organization }
    execution
    actor_membership { association :membership, organization: organization }
    event_type { "arrived_at_site" }
    occurred_at { Time.current }
  end
end
