class Asset < ApplicationRecord
  TYPES = %w[motor electrical_panel transformer generator vfd ups spda capacitor_bank other].freeze

  belongs_to :organization
  belongs_to :site

  normalizes :name, :tag, :manufacturer, :model, :serial_number,
             with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :asset_type, presence: true, inclusion: { in: TYPES }
  validate :site_belongs_to_organization

  private

  def site_belongs_to_organization
    return if site.nil? || organization.nil? || site.organization_id == organization_id

    errors.add(:site, :invalid)
  end
end
