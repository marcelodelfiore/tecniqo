FactoryBot.define do
  factory :evidence_reference do
    technical_record { association :finding }
    execution { technical_record.execution }
    organization { execution.organization }
    evidence { association :evidence, execution: execution }
    role { "supporting" }
  end
end
