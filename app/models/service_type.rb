class ServiceType < ApplicationRecord
  belongs_to :organization

  has_many :work_orders, dependent: :restrict_with_exception

  normalizes :name, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end
end
