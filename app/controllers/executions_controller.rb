class ExecutionsController < ApplicationController
  before_action :require_authentication
  before_action :set_work_order
  before_action :set_execution, only: :show
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def show
    authorize @execution
    @events = @execution.execution_events.includes(actor_membership: :user)
    @evidences = policy_scope(Evidence).where(execution: @execution)
                                       .includes(:uploaded_by_membership, original_attachment: :blob)
                                       .order(created_at: :desc)
    @participants = @execution.execution_participants.includes(membership: :user)
    @eligible_participants = policy_scope(Membership,
                                          policy_scope_class: ExecutionParticipantPolicy::EligibleScope)
  end

  def create
    execution = @work_order.executions.new(organization: Current.organization)
    authorize execution
    execution = Execution.create_for!(work_order: @work_order, created_by: Current.user,
                                      scheduled_start: execution_params[:scheduled_start])
    redirect_to work_order_execution_path(@work_order, execution.visit_number),
                notice: t("flash.executions.created", visit: execution.visit_number)
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @work_order, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_work_order
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order
  end

  def set_execution
    @execution = policy_scope(Execution).find_by(work_order: @work_order, visit_number: params[:id])
    raise Pundit::NotAuthorizedError unless @execution
  end

  def execution_params
    params.fetch(:execution, {}).permit(:scheduled_start)
  end
end
