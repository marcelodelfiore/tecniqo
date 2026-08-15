class DashboardsController < ApplicationController
  before_action :require_authentication
  after_action :verify_authorized

  def show
    authorize :dashboard, :show?
  end
end
