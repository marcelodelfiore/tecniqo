class Organization < ApplicationRecord
  has_many :memberships, dependent: :restrict_with_exception
  has_many :users, through: :memberships
  has_many :invitations, dependent: :restrict_with_exception
  has_many :customers, dependent: :restrict_with_exception
  has_many :sites, dependent: :restrict_with_exception
  has_many :assets, dependent: :restrict_with_exception

  validates :name, presence: true
end
