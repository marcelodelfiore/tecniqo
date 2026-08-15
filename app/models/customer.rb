class Customer < ApplicationRecord
  belongs_to :organization

  has_many :sites, dependent: :restrict_with_exception
  has_many :assets, through: :sites

  normalizes :name, :legal_name, :business_identifier, :email, :phone,
             with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
