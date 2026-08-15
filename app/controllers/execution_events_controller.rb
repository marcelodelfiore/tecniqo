class ExecutionEventsController < ApplicationController
  ACTION_EVENTS = {
    arrive: "arrived_at_site",
    start_work: "started_asset_work",
    pause: "paused_asset_work",
    resume: "resumed_asset_work",
    leave: "left_site",
    submit: "submitted"
  }.freeze

  before_action :require_authentication
  before_action :set_context
  after_action :verify_policy_scoped
  after_action :verify_authorized
  rescue_from ActiveRecord::RecordInvalid, ExecutionEvent::InvalidTransition,
              ExecutionEvent::IneligibleActor, ArgumentError, with: :handle_invalid_action

  ACTION_EVENTS.each do |action, event_type|
    define_method(action) do
      event = @execution.execution_events.new(organization: Current.organization)
      authorize event, :create?
      @execution.record_event!(event_type, actor_membership: current_membership,
                                           reason: action == :pause ? params[:reason].presence : nil)
      redirect_with_confirmation(event_type)
    end
  end

  def finish_work
    event = @execution.execution_events.new(organization: Current.organization)
    authorize event, :create?
    @execution.finish_work!(actor_membership: current_membership,
                            outcome: params[:outcome], outcome_reason: params[:outcome_reason],
                            outcome_note: params[:outcome_note])
    redirect_with_confirmation("finished_asset_work")
  end

  def unable
    event = @execution.execution_events.new(organization: Current.organization)
    authorize event, :create?
    @execution.mark_unable!(actor_membership: current_membership,
                            outcome_reason: params[:outcome_reason], outcome_note: params[:outcome_note])
    redirect_to execution_path, notice: t("flash.execution_events.unable_to_execute")
  end

  private

  def set_context
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order

    @execution = policy_scope(Execution).find_by(work_order: @work_order, visit_number: params[:execution_id])
    raise Pundit::NotAuthorizedError unless @execution
  end

  def current_membership
    Current.user.memberships.active.find_by(organization: Current.organization)
  end

  def redirect_with_confirmation(event_type)
    redirect_to execution_path,
                notice: t("flash.execution_events.recorded", event: t("execution_events.types.#{event_type}"))
  end

  def handle_invalid_action(error)
    redirect_to execution_path, alert: error_message(error)
  end

  def error_message(error)
    return error.record.errors.full_messages.to_sentence if error.respond_to?(:record)

    t("flash.execution_events.invalid_transition")
  end

  def execution_path
    work_order_execution_path(@work_order, @execution.visit_number)
  end
end
