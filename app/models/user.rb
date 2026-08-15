class User < ApplicationRecord
  has_many :login_tokens, dependent: :destroy
  has_many :memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                              inverse_of: :invited_by, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true
end
