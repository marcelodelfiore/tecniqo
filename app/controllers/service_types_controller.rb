class ServiceTypesController < ApplicationController
  before_action :require_authentication
  before_action :set_service_type, only: %i[show edit update activate deactivate]
  after_action :verify_policy_scoped, only: %i[index show edit update activate deactivate]
  after_action :verify_authorized

  def index
    authorize ServiceType
    @service_types = policy_scope(ServiceType).order(active: :desc, name: :asc)
  end

  def show
    authorize @service_type
  end

  def new
    @service_type = Current.organization.service_types.new
    authorize @service_type
  end

  def create
    @service_type = Current.organization.service_types.new(service_type_params)
    authorize @service_type

    if @service_type.save
      redirect_to service_types_path, notice: t("flash.service_types.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @service_type
  end

  def update
    authorize @service_type

    if @service_type.update(service_type_params)
      redirect_to service_types_path, notice: t("flash.service_types.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def activate
    authorize @service_type, :activate?
    @service_type.activate!
    redirect_to service_types_path, notice: t("flash.service_types.activated")
  end

  def deactivate
    authorize @service_type, :deactivate?
    @service_type.deactivate!
    redirect_to service_types_path, notice: t("flash.service_types.deactivated")
  end

  private

  def set_service_type
    @service_type = policy_scope(ServiceType).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @service_type
  end

  def service_type_params
    params.expect(service_type: %i[name description])
  end
end
