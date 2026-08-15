class User < ApplicationRecord
  has_many :login_tokens, dependent: :destroy
  has_many :memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :memberships
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id,
                              inverse_of: :invited_by, dependent: :restrict_with_exception
  has_many :created_work_orders, class_name: "WorkOrder", foreign_key: :created_by_id,
                                 inverse_of: :created_by, dependent: :restrict_with_exception
  has_many :made_assignments, class_name: "Assignment", foreign_key: :assigned_by_id,
                              inverse_of: :assigned_by, dependent: :restrict_with_exception
  has_many :created_executions, class_name: "Execution", foreign_key: :created_by_id,
                                inverse_of: :created_by, dependent: :restrict_with_exception
  has_many :added_execution_participants, class_name: "ExecutionParticipant", foreign_key: :added_by_id,
                                            inverse_of: :added_by, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true
end
