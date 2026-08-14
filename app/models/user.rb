class User < ApplicationRecord
  has_many :login_tokens, dependent: :destroy

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true
end
