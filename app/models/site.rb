class Site < ApplicationRecord
  belongs_to :organization
  belongs_to :customer

  has_many :assets, dependent: :restrict_with_exception
  has_many :work_orders, dependent: :restrict_with_exception

  normalizes :name, :contact_name, :phone, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true, uniqueness: { scope: :customer_id, case_sensitive: false }
  validate :customer_belongs_to_organization

  private

  def customer_belongs_to_organization
    return if customer.nil? || organization.nil? || customer.organization_id == organization_id

    errors.add(:customer, :invalid)
  end
end
