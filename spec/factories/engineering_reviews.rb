FactoryBot.define do
  factory :engineering_review do
    organization { work_order.organization }
    work_order
    state { "pending" }
  end
end
