class AssetsController < ApplicationController
  before_action :require_authentication
  before_action :set_customer_and_site
  before_action :set_asset, only: %i[show edit update]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def show
    authorize @asset
  end

  def new
    @asset = @site.assets.new(organization: Current.organization)
    authorize @asset
  end

  def create
    @asset = @site.assets.new(asset_params.merge(organization: Current.organization))
    authorize @asset

    if @asset.save
      redirect_to [ @customer, @site, @asset ], notice: t("flash.assets.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @asset
  end

  def update
    authorize @asset

    if @asset.update(asset_params)
      redirect_to [ @customer, @site, @asset ], notice: t("flash.assets.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_customer_and_site
    @customer = policy_scope(Customer).find_by(id: params[:customer_id])
    raise Pundit::NotAuthorizedError unless @customer

    @site = policy_scope(Site).where(customer: @customer).find_by(id: params[:site_id])
    raise Pundit::NotAuthorizedError unless @site
  end

  def set_asset
    @asset = policy_scope(Asset).where(site: @site).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @asset
  end

  def asset_params
    params.expect(asset: %i[name asset_type tag manufacturer model serial_number])
  end
end
