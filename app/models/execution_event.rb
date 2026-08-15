class ExecutionEvent < ApplicationRecord
  class InvalidTransition < StandardError; end
  class IneligibleActor < StandardError; end

  TYPES = %w[
    arrived_at_site started_asset_work paused_asset_work resumed_asset_work
    finished_asset_work left_site submitted
  ].freeze
  PAUSE_REASONS = %w[customer_request access_wait production safety material break other].freeze

  belongs_to :organization
  belongs_to :execution, inverse_of: :execution_events
  belongs_to :actor_membership, class_name: "Membership"

  has_one :actor, through: :actor_membership, source: :user

  attr_readonly :organization_id, :execution_id, :actor_membership_id, :event_type,
                :occurred_at, :reason

  validates :event_type, inclusion: { in: TYPES }
  validates :occurred_at, presence: true
  validates :reason, inclusion: { in: PAUSE_REASONS }, allow_nil: true
  validate :reason_only_for_pause
  validate :relationships_belong_to_organization
  before_update :prevent_update
  before_destroy :prevent_destroy

  scope :chronological, -> { order(:occurred_at, :id) }

  private

  def reason_only_for_pause
    errors.add(:reason, :invalid) if reason && event_type != "paused_asset_work"
  end

  def relationships_belong_to_organization
    return if organization.nil?

    errors.add(:execution, :invalid) if execution && execution.organization_id != organization_id
    errors.add(:actor_membership, :invalid) if actor_membership && actor_membership.organization_id != organization_id
  end

  def prevent_destroy
    errors.add(:base, :event_immutable)
    throw :abort
  end

  def prevent_update
    errors.add(:base, :event_immutable)
    throw :abort
  end
end
