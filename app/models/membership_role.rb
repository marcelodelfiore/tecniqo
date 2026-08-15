class MembershipRole < ApplicationRecord
  ROLES = %w[administrator supervisor technician engineer].freeze

  belongs_to :membership

  validates :role, presence: true,
                   inclusion: { in: ROLES },
                   uniqueness: { scope: :membership_id }
end
