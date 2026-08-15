class SitesController < ApplicationController
  before_action :require_authentication
  before_action :set_customer
  before_action :set_site, only: %i[show edit update]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def show
    authorize @site
    @assets = policy_scope(Asset).where(site: @site).order(:name)
  end

  def new
    @site = @customer.sites.new(organization: Current.organization)
    authorize @site
  end

  def create
    @site = @customer.sites.new(site_params.merge(organization: Current.organization))
    authorize @site

    if @site.save
      redirect_to [ @customer, @site ], notice: t("flash.sites.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @site
  end

  def update
    authorize @site

    if @site.update(site_params)
      redirect_to [ @customer, @site ], notice: t("flash.sites.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_customer
    @customer = policy_scope(Customer).find_by(id: params[:customer_id])
    raise Pundit::NotAuthorizedError unless @customer
  end

  def set_site
    @site = policy_scope(Site).where(customer: @customer).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @site
  end

  def site_params
    params.expect(site: %i[name address contact_name phone notes])
  end
end
