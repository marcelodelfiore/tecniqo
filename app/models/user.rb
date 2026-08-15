class User < ApplicationRecord
  has_many :login_tokens, dependent: :destroy
  has_many :memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :memberships

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true
end
