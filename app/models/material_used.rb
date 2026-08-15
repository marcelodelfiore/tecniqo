class MaterialUsed < ApplicationRecord
  include ExecutionTechnicalRecord

  self.table_name = "materials_used"

  UNITS = %w[piece m cm mm kg g L mL].freeze

  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit, inclusion: { in: UNITS }

  def display_quantity
    quantity.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
  end
end
