class CustomersController < ApplicationController
  before_action :require_authentication
  before_action :set_customer, only: %i[show edit update]
  after_action :verify_policy_scoped, only: %i[index show edit update]
  after_action :verify_authorized

  def index
    authorize Customer
    customers = policy_scope(Customer)
    if params[:query].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
      customers = customers.where("customers.name ILIKE ?", pattern)
    end
    @customers = customers.left_joins(sites: :assets)
                          .select("customers.*, COUNT(DISTINCT sites.id) AS sites_count, COUNT(assets.id) AS assets_count")
                          .group("customers.id")
                          .order(:name)
  end

  def show
    authorize @customer
    @sites = policy_scope(Site).where(customer: @customer)
                               .left_joins(:assets)
                               .select("sites.*, COUNT(assets.id) AS assets_count")
                               .group("sites.id")
                               .order(:name)
  end

  def new
    @customer = Current.organization.customers.new
    authorize @customer
  end

  def create
    @customer = Current.organization.customers.new(customer_params)
    authorize @customer

    if @customer.save
      redirect_to @customer, notice: t("flash.customers.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @customer
  end

  def update
    authorize @customer

    if @customer.update(customer_params)
      redirect_to @customer, notice: t("flash.customers.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_customer
    @customer = policy_scope(Customer).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @customer
  end

  def customer_params
    params.expect(customer: %i[name legal_name business_identifier email phone notes])
  end
end
