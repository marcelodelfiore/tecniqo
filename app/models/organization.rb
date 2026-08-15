class Organization < ApplicationRecord
  has_many :memberships, dependent: :restrict_with_exception
  has_many :users, through: :memberships

  validates :name, presence: true
end
