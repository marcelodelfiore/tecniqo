class Organization < ApplicationRecord
  has_many :memberships, dependent: :restrict_with_exception
  has_many :users, through: :memberships
  has_many :invitations, dependent: :restrict_with_exception
  has_many :customers, dependent: :restrict_with_exception
  has_many :sites, dependent: :restrict_with_exception
  has_many :assets, dependent: :restrict_with_exception
  has_many :service_types, dependent: :restrict_with_exception
  has_many :work_orders, dependent: :restrict_with_exception
  has_many :assignments, dependent: :restrict_with_exception
  has_many :executions, dependent: :restrict_with_exception
  has_many :execution_participants, dependent: :restrict_with_exception
  has_many :execution_events, dependent: :restrict_with_exception
  has_many :evidences, dependent: :restrict_with_exception

  validates :name, presence: true
end
