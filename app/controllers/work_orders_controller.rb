class WorkOrdersController < ApplicationController
  before_action :require_authentication
  before_action :set_work_order, only: %i[show edit update]
  before_action :load_form_options, only: %i[new create edit update]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def index
    authorize WorkOrder
    work_orders = policy_scope(WorkOrder)
    if params[:query].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
      work_orders = work_orders.joins(:customer).where(
        "work_orders.public_identifier ILIKE :pattern OR customers.name ILIKE :pattern",
        pattern: pattern
      )
    end
    @work_orders = work_orders.includes(:customer, :site, :asset, :service_type,
                                        current_assignment: { membership: :user })
                               .order(scheduled_start: :asc, created_at: :desc)
  end

  def show
    authorize @work_order
    @assignments = @work_order.assignments.includes(:assigned_by, membership: :user)
    @executions = policy_scope(Execution).where(work_order: @work_order)
                                         .includes(:execution_events, execution_participants: { membership: :user })
    @technicians = policy_scope(Membership, policy_scope_class: AssignmentPolicy::AssignableScope)
    @engineering_review = policy_scope(EngineeringReview).find_by(work_order: @work_order)
  end

  def new
    @work_order = Current.organization.work_orders.new(context_attributes)
    authorize @work_order
  end

  def create
    @work_order = Current.organization.work_orders.new(work_order_attributes)
    authorize @work_order
    assignee = selected_assignee

    @work_order = WorkOrder.issue!(organization: Current.organization,
                                   attributes: work_order_attributes,
                                   created_by: Current.user,
                                   assignee_membership: assignee)
    redirect_to @work_order, notice: t("flash.work_orders.created")
  rescue ActiveRecord::RecordInvalid => error
    @work_order = error.record.is_a?(WorkOrder) ? error.record : @work_order
    render :new, status: :unprocessable_content
  end

  def edit
    authorize @work_order
  end

  def update
    authorize @work_order

    if @work_order.update(work_order_attributes)
      redirect_to @work_order, notice: t("flash.work_orders.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_work_order
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:id])
    raise Pundit::NotAuthorizedError unless @work_order
  end

  def load_form_options
    @customers = policy_scope(Customer).order(:name)
    @sites = policy_scope(Site).includes(:customer).order(:name)
    @assets = policy_scope(Asset).includes(:site).order(:name)
    service_types = policy_scope(ServiceType)
    @service_types = if @work_order&.persisted?
      service_types.where(active: true).or(service_types.where(id: @work_order.service_type_id)).order(:name)
    else
      service_types.active.order(:name)
    end
    @technicians = policy_scope(Membership, policy_scope_class: AssignmentPolicy::AssignableScope)
  end

  def context_attributes
    attributes = {}
    attributes[:customer] = @customers.find_by(id: params[:customer_id]) if params[:customer_id].present?
    attributes[:site] = @sites.find_by(id: params[:site_id]) if params[:site_id].present?
    attributes[:asset] = @assets.find_by(id: params[:asset_id]) if params[:asset_id].present?
    attributes.compact
  end

  def work_order_attributes
    permitted = work_order_params
    {
      customer: @customers.find_by(id: permitted[:customer_id]),
      site: @sites.find_by(id: permitted[:site_id]),
      asset: permitted[:asset_id].present? ? @assets.find_by(id: permitted[:asset_id]) : nil,
      service_type: @service_types.find_by(id: permitted[:service_type_id]),
      requested_work: permitted[:requested_work],
      priority: permitted[:priority],
      scheduled_start: permitted[:scheduled_start]
    }
  end

  def selected_assignee
    return if work_order_params[:technician_membership_id].blank?

    @technicians.find_by(id: work_order_params[:technician_membership_id]) ||
      raise(Pundit::NotAuthorizedError)
  end

  def work_order_params
    params.expect(work_order: %i[customer_id site_id asset_id service_type_id requested_work priority
                                 scheduled_start technician_membership_id])
  end
end
