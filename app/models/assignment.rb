class Assignment < ApplicationRecord
  belongs_to :organization
  belongs_to :work_order, inverse_of: :assignments
  belongs_to :membership
  belongs_to :assigned_by, class_name: "User"

  has_one :assignee, through: :membership, source: :user

  attr_readonly :organization_id, :work_order_id, :membership_id, :assigned_by_id, :assigned_at

  validates :assigned_at, presence: true
  validate :relationships_belong_to_organization
  validate :membership_is_eligible_technician, on: :create
  validate :ended_at_follows_assignment
  validate :ended_at_changes_only_once, on: :update

  scope :current, -> { where(ended_at: nil) }

  def current?
    ended_at.nil?
  end

  def end_at!(timestamp)
    update!(ended_at: timestamp)
  end

  private

  def relationships_belong_to_organization
    return if organization.nil?

    errors.add(:work_order, :invalid) if work_order && work_order.organization_id != organization_id
    errors.add(:membership, :invalid) if membership && membership.organization_id != organization_id
  end

  def membership_is_eligible_technician
    return if membership&.active? && membership.membership_roles.exists?(role: "technician")

    errors.add(:membership, :invalid_assignee)
  end

  def ended_at_follows_assignment
    errors.add(:ended_at, :invalid) if ended_at && assigned_at && ended_at < assigned_at
  end

  def ended_at_changes_only_once
    errors.add(:ended_at, :taken) if ended_at_was.present? && will_save_change_to_ended_at?
  end
end
