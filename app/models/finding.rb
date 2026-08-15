class Finding < ApplicationRecord
  include ExecutionTechnicalRecord

  SEVERITIES = %w[minor significant critical].freeze

  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :description, presence: true
  validates :severity, inclusion: { in: SEVERITIES }
end
