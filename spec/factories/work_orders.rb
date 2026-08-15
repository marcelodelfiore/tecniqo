FactoryBot.define do
  factory :work_order do
    organization { customer.organization }
    customer
    site { association :site, customer: customer }
    service_type { association :service_type, organization: organization }
    created_by { association :user }
    sequence(:sequence_number)
    public_identifier { format("OS-%<year>d-%<number>06d", year: Time.current.year, number: sequence_number) }
    requested_work { "Inspect the reported equipment problem." }
    priority { "normal" }
  end
end
