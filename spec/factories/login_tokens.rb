FactoryBot.define do
  factory :login_token do
    association :user
    token_digest { SecureRandom.hex(32) }
    expires_at { 15.minutes.from_now }
    used_at { nil }
  end
end
