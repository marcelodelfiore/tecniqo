FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user-#{number}@example.com" }
    last_seen_at { nil }
    founder { false }
  end
end
