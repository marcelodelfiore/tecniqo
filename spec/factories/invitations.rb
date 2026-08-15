FactoryBot.define do
  factory :invitation do
    organization
    association :invited_by, factory: :user
    sequence(:email) { |number| "invited-#{number}@example.com" }
    roles { [ "technician" ] }
    sequence(:token_digest) { |number| Invitation.digest("invitation-token-#{number}") }
    expires_at { Invitation::TOKEN_TTL.from_now }
  end
end
