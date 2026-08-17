class Execution < ApplicationRecord
  OUTCOMES = %w[completed return_required unable_to_execute].freeze
  OUTCOME_REASONS = %w[
    material_required customer_unavailable equipment_unavailable
    additional_personnel_required additional_diagnosis_required access_denied
    unsafe_condition wrong_equipment production_unavailable other
  ].freeze
  EVENT_TRANSITIONS = {
    "planned" => %w[arrived_at_site],
    "onsite_waiting" => %w[started_asset_work],
    "working" => %w[paused_asset_work finished_asset_work],
    "paused" => %w[resumed_asset_work],
    "work_finished" => %w[left_site],
    "unable_to_execute" => %w[left_site],
    "left_site" => %w[submitted],
    "submitted" => []
  }.freeze
  STATE_BY_EVENT = {
    "arrived_at_site" => "onsite_waiting",
    "started_asset_work" => "working",
    "paused_asset_work" => "paused",
    "resumed_asset_work" => "working",
    "finished_asset_work" => "work_finished",
    "left_site" => "left_site",
    "submitted" => "submitted"
  }.freeze

  belongs_to :organization
  belongs_to :work_order
  belongs_to :created_by, class_name: "User"
  belongs_to :outcome_recorded_by_membership, class_name: "Membership", optional: true

  has_many :execution_participants, dependent: :restrict_with_exception
  has_many :participant_memberships, through: :execution_participants, source: :membership
  has_many :execution_events, -> { chronological }, dependent: :restrict_with_exception,
                                                    inverse_of: :execution
  has_many :evidences, dependent: :restrict_with_exception
  has_many :findings, -> { chronological }, dependent: :restrict_with_exception
  has_many :measurements, -> { chronological }, dependent: :restrict_with_exception
  has_many :action_performeds, -> { chronological }, dependent: :restrict_with_exception
  has_many :materials_used, -> { chronological }, class_name: "MaterialUsed",
                                                  dependent: :restrict_with_exception
  has_many :recommendations, -> { chronological }, dependent: :restrict_with_exception
  has_many :engineering_review_executions, dependent: :restrict_with_exception
  has_many :engineering_reviews, through: :engineering_review_executions
  has_many :clarification_requests, dependent: :restrict_with_exception

  normalizes :outcome_note, with: ->(value) { value.to_s.strip.presence }

  validates :visit_number, numericality: { only_integer: true, greater_than: 0 },
                           uniqueness: { scope: :work_order_id }
  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true
  validates :outcome_reason, inclusion: { in: OUTCOME_REASONS }, allow_nil: true
  validate :work_order_belongs_to_organization
  validate :outcome_metadata_is_consistent
  validate :submitted_execution_is_unchanged, on: :update

  def self.create_for!(work_order:, created_by:, scheduled_start: nil)
    work_order.with_lock do
      previous = work_order.executions.order(visit_number: :desc).first
      if previous && !(previous.submitted? && previous.outcome == "return_required")
        work_order.errors.add(:executions, :return_not_available)
        raise ActiveRecord::RecordInvalid, work_order
      end

      execution = work_order.executions.create!(
        organization: work_order.organization,
        created_by: created_by,
        visit_number: previous ? previous.visit_number + 1 : 1,
        scheduled_start: scheduled_start || (work_order.scheduled_start if previous.nil?)
      )
      assignment = work_order.current_assignment
      unless assignment
        execution.errors.add(:execution_participants, :blank)
        raise ActiveRecord::RecordInvalid, execution
      end
      execution.add_participant!(assignment.membership, added_by: created_by)
      execution
    end
  end

  def add_participant!(membership, added_by:)
    raise_locked! if submitted?

    execution_participants.find_or_create_by!(membership: membership) do |participant|
      participant.organization = organization
      participant.added_by = added_by
    end
  end

  def record_event!(event_type, actor_membership:, reason: nil, occurred_at: Time.current)
    with_lock do
      ensure_actor_can_act!(actor_membership)
      validate_transition!(event_type)
      validate_chronology!(occurred_at)
      event = execution_events.create!(organization: organization, actor_membership: actor_membership,
                                       event_type: event_type, occurred_at: occurred_at, reason: reason)
      EngineeringReview.create_for_ready_work_order!(work_order) if event_type == "submitted"
      event
    end
  end

  def finish_work!(actor_membership:, outcome:, outcome_reason: nil, outcome_note: nil,
                   occurred_at: Time.current)
    with_lock do
      ensure_actor_can_act!(actor_membership)
      raise ArgumentError, "invalid finish outcome" unless %w[completed return_required].include?(outcome)

      validate_transition!("finished_asset_work")
      validate_chronology!(occurred_at)
      assign_outcome!(outcome, outcome_reason, outcome_note, actor_membership, occurred_at)
      save!
      execution_events.create!(organization: organization, actor_membership: actor_membership,
                               event_type: "finished_asset_work", occurred_at: occurred_at)
    end
  end

  def mark_unable!(actor_membership:, outcome_reason:, outcome_note: nil, occurred_at: Time.current)
    with_lock do
      ensure_actor_can_act!(actor_membership)
      raise ExecutionEvent::InvalidTransition unless current_state == "onsite_waiting" && outcome.nil?
      validate_chronology!(occurred_at)

      assign_outcome!("unable_to_execute", outcome_reason, outcome_note, actor_membership, occurred_at)
      save!
    end
  end

  def current_state
    return "submitted" if last_event_type == "submitted"
    return "unable_to_execute" if outcome == "unable_to_execute" && last_event_type == "arrived_at_site"

    STATE_BY_EVENT.fetch(last_event_type, "planned")
  end

  def next_event_types
    EVENT_TRANSITIONS.fetch(current_state)
  end

  def submitted?
    last_event_type == "submitted"
  end

  def to_param
    visit_number.to_s
  end

  def participant?(membership)
    membership && execution_participants.exists?(membership: membership)
  end

  def site_presence_duration
    interval_between("arrived_at_site", "left_site")
  end

  def pre_work_wait_duration
    interval_between("arrived_at_site", "started_asset_work")
  end

  def effective_work_duration
    accumulated_duration(start_types: %w[started_asset_work resumed_asset_work],
                         stop_types: %w[paused_asset_work finished_asset_work])
  end

  def paused_duration
    accumulated_duration(start_types: %w[paused_asset_work], stop_types: %w[resumed_asset_work])
  end

  def post_work_onsite_duration
    interval_between("finished_asset_work", "left_site")
  end

  private

  def ordered_events
    execution_events.chronological.to_a
  end

  def last_event_type
    execution_events.chronological.last&.event_type
  end

  def validate_transition!(event_type)
    raise ExecutionEvent::InvalidTransition unless next_event_types.include?(event_type)
    raise ExecutionEvent::InvalidTransition if event_type == "submitted" && outcome.nil?
  end

  def validate_chronology!(occurred_at)
    latest = execution_events.chronological.last
    raise ExecutionEvent::InvalidTransition if latest && occurred_at < latest.occurred_at
  end

  def ensure_actor_can_act!(membership)
    raise ExecutionEvent::IneligibleActor unless participant?(membership) && membership.active? &&
                                                       membership.organization_id == organization_id &&
                                                       membership.membership_roles.exists?(role: "technician")
  end

  def assign_outcome!(value, reason, note, membership, timestamp)
    self.outcome = value
    self.outcome_reason = value == "completed" ? nil : reason.presence
    self.outcome_note = note
    self.outcome_recorded_at = timestamp
    self.outcome_recorded_by_membership = membership
  end

  def interval_between(start_type, finish_type)
    events = ordered_events
    started = events.find { |event| event.event_type == start_type }
    finished = events.find { |event| event.event_type == finish_type && started && event.occurred_at >= started.occurred_at }
    finished && started ? finished.occurred_at - started.occurred_at : nil
  end

  def accumulated_duration(start_types:, stop_types:)
    total = 0.0
    started_at = nil
    ordered_events.each do |event|
      started_at = event.occurred_at if start_types.include?(event.event_type)
      if started_at && stop_types.include?(event.event_type)
        total += event.occurred_at - started_at
        started_at = nil
      end
    end
    total
  end

  def work_order_belongs_to_organization
    errors.add(:work_order, :invalid) if work_order && organization && work_order.organization_id != organization_id
    if outcome_recorded_by_membership && organization &&
       outcome_recorded_by_membership.organization_id != organization_id
      errors.add(:outcome_recorded_by_membership, :invalid)
    end
  end

  def outcome_metadata_is_consistent
    if outcome.nil?
      errors.add(:outcome, :invalid) if outcome_reason || outcome_recorded_at || outcome_recorded_by_membership
    elsif outcome == "completed"
      errors.add(:outcome_reason, :invalid) if outcome_reason
    else
      errors.add(:outcome_reason, :blank) if outcome_reason.blank?
    end
    errors.add(:outcome_recorded_at, :blank) if outcome && outcome_recorded_at.blank?
    errors.add(:outcome_recorded_by_membership, :blank) if outcome && outcome_recorded_by_membership.nil?
  end

  def submitted_execution_is_unchanged
    return unless execution_events.where(event_type: "submitted").exists?
    return unless changes_to_save.except("updated_at").present?

    errors.add(:base, :execution_submitted)
  end

  def raise_locked!
    errors.add(:base, :execution_submitted)
    raise ActiveRecord::RecordInvalid, self
  end
end
