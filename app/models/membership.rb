class Membership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  has_many :membership_roles, dependent: :destroy

  validates :user_id, uniqueness: { scope: :organization_id }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
end
