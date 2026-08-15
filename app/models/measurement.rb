class Measurement < ApplicationRecord
  include ExecutionTechnicalRecord

  QUANTITY_UNITS = {
    "voltage" => %w[mV V kV],
    "current" => %w[mA A],
    "frequency" => %w[Hz],
    "resistance" => %w[ohm kohm Mohm],
    "insulation_resistance" => %w[kohm Mohm Gohm],
    "continuity" => %w[ohm],
    "temperature" => %w[degC]
  }.freeze
  DEFAULT_UNITS = QUANTITY_UNITS.transform_values(&:first).merge(
    "voltage" => "V", "current" => "A", "resistance" => "ohm",
    "insulation_resistance" => "Mohm"
  ).freeze

  normalizes :measurement_point, with: ->(value) { value.to_s.strip.presence }

  validates :quantity, inclusion: { in: QUANTITY_UNITS.keys }
  validates :value, numericality: true
  validates :unit, presence: true
  validates :measurement_point, presence: true
  validate :unit_matches_quantity

  def self.units_for(quantity)
    QUANTITY_UNITS.fetch(quantity.to_s, [])
  end

  def display_value
    value.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
  end

  private

  def unit_matches_quantity
    return if quantity.blank? || unit.blank? || unit.in?(self.class.units_for(quantity))

    errors.add(:unit, :incompatible, quantity: I18n.t("measurement_quantities.#{quantity}"))
  end
end
