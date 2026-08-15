class AssignmentsController < ApplicationController
  before_action :require_authentication
  before_action :set_work_order
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def create
    assignment = @work_order.assignments.new(organization: Current.organization)
    authorize assignment
    technicians = policy_scope(Membership, policy_scope_class: AssignmentPolicy::AssignableScope)
    membership = technicians.find_by(id: params[:membership_id])
    raise Pundit::NotAuthorizedError unless membership

    @work_order.assign_to!(membership, assigned_by: Current.user)
    redirect_to @work_order, notice: t("flash.assignments.updated")
  end

  private

  def set_work_order
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order
  end
end
