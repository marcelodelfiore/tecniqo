FactoryBot.define do
  factory :clarification_evidence do
    organization { clarification_request.organization }
    clarification_request
    evidence { association :evidence, execution: clarification_request.execution }
  end
end
