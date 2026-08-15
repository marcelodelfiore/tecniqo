class ActionPerformed < ApplicationRecord
  include ExecutionTechnicalRecord

  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :description, presence: true
end
