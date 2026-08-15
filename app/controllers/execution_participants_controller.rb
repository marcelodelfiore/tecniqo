class ExecutionParticipantsController < ApplicationController
  before_action :require_authentication
  before_action :set_context
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def create
    participant = @execution.execution_participants.new(organization: Current.organization)
    authorize participant
    eligible = policy_scope(Membership, policy_scope_class: ExecutionParticipantPolicy::EligibleScope)
    membership = eligible.find_by(id: params[:membership_id])
    raise Pundit::NotAuthorizedError unless membership

    @execution.add_participant!(membership, added_by: Current.user)
    redirect_to execution_path, notice: t("flash.execution_participants.added")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to execution_path, alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    participant = @execution.execution_participants.find(params[:id])
    authorize participant
    participant.destroy!
    redirect_to execution_path, notice: t("flash.execution_participants.removed")
  rescue ActiveRecord::RecordNotDestroyed => error
    redirect_to execution_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_context
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order

    @execution = policy_scope(Execution).find_by(work_order: @work_order, visit_number: params[:execution_id])
    raise Pundit::NotAuthorizedError unless @execution
  end

  def execution_path
    work_order_execution_path(@work_order, @execution.visit_number)
  end
end
