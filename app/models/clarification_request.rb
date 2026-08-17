class ClarificationRequest < ApplicationRecord
  STATES = %w[requested responded resolved].freeze
  TARGET_TYPES = %w[
    WorkOrder Execution Finding Measurement ActionPerformed MaterialUsed Recommendation Evidence
  ].freeze

  belongs_to :organization
  belongs_to :engineering_review, touch: true
  belongs_to :execution
  belongs_to :target, polymorphic: true
  belongs_to :requested_by, class_name: "User"
  belongs_to :recipient_membership, class_name: "Membership"
  belongs_to :responded_by_membership, class_name: "Membership", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many :clarification_evidences, dependent: :restrict_with_exception
  has_many :evidences, through: :clarification_evidences

  normalizes :question, :response, with: ->(value) { value.to_s.strip.presence }

  validates :question, :requested_at, presence: true
  validates :state, inclusion: { in: STATES }
  validates :target_type, inclusion: { in: TARGET_TYPES }
  validate :context_is_consistent
  validate :recipient_is_eligible
  validate :lifecycle_is_consistent

  scope :unresolved, -> { where.not(state: "resolved") }

  def self.request!(review:, execution:, target:, recipient_membership:, question:, actor:)
    transaction do
      review.lock!
      raise_invalid_review!(review) unless review.state == "in_review" && review.reviewer?(actor)

      clarification = create!(organization: review.organization, engineering_review: review,
                              execution: execution, target: target, requested_by: actor,
                              recipient_membership: recipient_membership, question: question,
                              requested_at: Time.current)
      review.mark_changes_requested!
      clarification
    end
  end

  def respond!(actor_membership:, response:, evidence_ids: [])
    with_lock do
      return self if state == "responded" && responded_by_membership == actor_membership &&
                     self.response == response.to_s.strip

      raise_invalid_transition! unless state == "requested" && recipient_membership == actor_membership
      selected = execution.evidences.where(id: Array(evidence_ids).compact_blank).to_a
      raise ActiveRecord::RecordNotFound unless selected.size == Array(evidence_ids).compact_blank.uniq.size

      update!(state: "responded", response: response, responded_by_membership: actor_membership,
              responded_at: Time.current)
      selected.each do |evidence|
        clarification_evidences.find_or_create_by!(evidence: evidence) do |link|
          link.organization = organization
        end
      end
    end
  end

  def resolve!(actor:)
    with_lock do
      return self if state == "resolved" && resolved_by == actor

      raise_invalid_transition! unless state == "responded" && engineering_review.reviewer?(actor)
      update!(state: "resolved", resolved_by: actor, resolved_at: Time.current)
      engineering_review.resume_if_resolved!
    end
  end

  private

  def context_is_consistent
    return unless organization && engineering_review && execution

    errors.add(:engineering_review, :invalid) if engineering_review.organization_id != organization_id
    unless execution.organization_id == organization_id &&
           execution.work_order_id == engineering_review.work_order_id &&
           engineering_review.executions.exists?(execution.id)
      errors.add(:execution, :invalid)
    end
    errors.add(:target, :invalid) unless target_in_context?
  end

  def target_in_context?
    case target
    when WorkOrder then target == engineering_review.work_order
    when Execution then target == execution
    when Evidence then target.execution_id == execution_id
    else target.respond_to?(:execution_id) && target.execution_id == execution_id
    end
  end

  def recipient_is_eligible
    return unless recipient_membership && execution
    return if recipient_membership.active? && recipient_membership.organization_id == organization_id &&
              recipient_membership.membership_roles.exists?(role: "technician") &&
              execution.participant?(recipient_membership)

    errors.add(:recipient_membership, :invalid)
  end

  def lifecycle_is_consistent
    if state == "requested"
      errors.add(:response, :invalid) if response || responded_by_membership || responded_at || resolved_by || resolved_at
    else
      errors.add(:response, :blank) if response.blank?
      errors.add(:responded_by_membership, :blank) unless responded_by_membership
      errors.add(:responded_at, :blank) unless responded_at
    end
    return unless state == "resolved"

    errors.add(:resolved_by, :blank) unless resolved_by
    errors.add(:resolved_at, :blank) unless resolved_at
  end

  def raise_invalid_transition!
    errors.add(:state, :invalid)
    raise ActiveRecord::RecordInvalid, self
  end

  def self.raise_invalid_review!(review)
    review.errors.add(:state, :invalid)
    raise ActiveRecord::RecordInvalid, review
  end
  private_class_method :raise_invalid_review!
end
