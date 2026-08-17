class EngineeringReview < ApplicationRecord
  STATES = %w[pending in_review changes_requested approved].freeze

  belongs_to :organization
  belongs_to :work_order
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  has_many :engineering_review_executions, dependent: :restrict_with_exception
  has_many :executions, through: :engineering_review_executions
  has_many :clarification_requests, dependent: :restrict_with_exception

  validates :state, inclusion: { in: STATES }
  validates :work_order_id, uniqueness: true
  validate :work_order_belongs_to_organization
  validate :reviewer_state_is_consistent
  validate :approval_state_is_consistent
  validate :actors_are_eligible_reviewers

  scope :actionable, -> { where.not(state: "approved") }

  def self.create_for_ready_work_order!(work_order)
    return unless work_order.ready_for_engineering_review?

    work_order.with_lock do
      review = find_or_create_by!(work_order: work_order) do |candidate|
        candidate.organization = work_order.organization
      end
      Execution.where(work_order: work_order).order(:visit_number).select(&:submitted?).each do |execution|
        review.engineering_review_executions.find_or_create_by!(execution: execution) do |included|
          included.organization = work_order.organization
        end
      end
      review
    end
  end

  def start!(actor:)
    with_lock do
      return self if state == "in_review" && reviewer == actor

      raise_invalid_transition! unless state == "pending"
      ensure_reviewer_eligible!(actor)
      update!(state: "in_review", reviewer: actor, started_at: Time.current)
    end
  end

  def mark_changes_requested!
    with_lock do
      raise_invalid_transition! unless state.in?(%w[in_review changes_requested])
      update!(state: "changes_requested") unless state == "changes_requested"
    end
  end

  def resume_if_resolved!
    with_lock do
      return unless state == "changes_requested"
      return if clarification_requests.where.not(state: "resolved").exists?

      update!(state: "in_review")
    end
  end

  def approve!(actor:)
    with_lock do
      return self if state == "approved" && approved_by == actor

      raise_invalid_transition! unless state == "in_review" && reviewer == actor
      raise_unresolved_clarifications! if clarification_requests.where.not(state: "resolved").exists?
      raise_invalid_transition! unless work_order.ready_for_engineering_review?
      ensure_review_scope_unchanged!
      update!(state: "approved", approved_by: actor, approved_at: Time.current)
    end
  end

  def reviewer?(user)
    reviewer_id == user&.id
  end

  private

  def work_order_belongs_to_organization
    errors.add(:work_order, :invalid) if work_order && organization && work_order.organization_id != organization_id
  end

  def reviewer_state_is_consistent
    if state == "pending"
      errors.add(:reviewer, :invalid) if reviewer || started_at
    else
      errors.add(:reviewer, :blank) unless reviewer
      errors.add(:started_at, :blank) unless started_at
    end
  end

  def approval_state_is_consistent
    if state == "approved"
      errors.add(:approved_by, :blank) unless approved_by
      errors.add(:approved_at, :blank) unless approved_at
    elsif approved_by || approved_at
      errors.add(:approved_by, :invalid)
    end
  end

  def actors_are_eligible_reviewers
    errors.add(:reviewer, :invalid) if reviewer && !eligible_reviewer?(reviewer)
    errors.add(:approved_by, :invalid) if approved_by && !eligible_reviewer?(approved_by)
  end

  def eligible_reviewer?(user)
    user.founder? || user.memberships.active.joins(:membership_roles)
                        .exists?(organization: organization, membership_roles: { role: "engineer" })
  end

  def ensure_reviewer_eligible!(actor)
    return if eligible_reviewer?(actor)

    errors.add(:reviewer, :invalid)
    raise ActiveRecord::RecordInvalid, self
  end

  def ensure_review_scope_unchanged!
    submitted_ids = Execution.where(work_order: work_order).select(&:submitted?).map(&:id).sort
    raise_invalid_transition! unless executions.ids.sort == submitted_ids
  end

  def raise_invalid_transition!
    errors.add(:state, :invalid)
    raise ActiveRecord::RecordInvalid, self
  end

  def raise_unresolved_clarifications!
    errors.add(:clarification_requests, :unresolved)
    raise ActiveRecord::RecordInvalid, self
  end
end
