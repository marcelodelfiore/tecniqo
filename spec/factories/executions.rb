FactoryBot.define do
  factory :execution do
    organization { work_order.organization }
    work_order
    created_by { association :user }
    sequence(:visit_number)
    scheduled_start { 1.day.from_now }
  end
end
