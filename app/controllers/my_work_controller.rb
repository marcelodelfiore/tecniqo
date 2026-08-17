class MyWorkController < ApplicationController
  before_action :require_authentication
  after_action :verify_authorized
  after_action :verify_policy_scoped

  def index
    authorize :my_work, :show?
    @executions = policy_scope(Execution).includes(work_order: %i[customer site asset service_type])
                                         .order(:scheduled_start, :visit_number)
    membership = Current.user.memberships.active.find_by!(organization: Current.organization)
    @clarifications = policy_scope(ClarificationRequest)
                      .where(recipient_membership: membership).where.not(state: "resolved")
                      .includes(:requested_by, engineering_review: { work_order: :asset })
                      .order(:requested_at, :id)
    @assigned_work_orders = policy_scope(WorkOrder)
                            .joins(:assignments)
                            .where(assignments: { membership_id: membership.id, ended_at: nil })
                            .where.not(id: @executions.map(&:work_order_id))
                            .includes(:customer, :site, :asset, :service_type)
                            .order(:scheduled_start)
  end
end
