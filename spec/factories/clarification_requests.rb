FactoryBot.define do
  factory :clarification_request do
    organization { engineering_review.organization }
    engineering_review
    execution { engineering_review.executions.first }
    target { execution }
    requested_by { engineering_review.reviewer }
    recipient_membership { execution.participant_memberships.first }
    question { "Was this measurement captured under normal operating load?" }
    state { "requested" }
    requested_at { Time.current }
  end
end
