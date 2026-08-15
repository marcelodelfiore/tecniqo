# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
if Rails.env.development?
  organization = Organization.find_or_create_by!(name: "Técniqo Demo Maintenance")
  founder = User.find_or_create_by!(email: "founder@tecniqo.local") do |user|
    user.founder = true
  end
  founder.update!(founder: true) unless founder.founder?

  membership = Membership.find_or_create_by!(organization: organization, user: founder)
  membership.update!(active: true)
  membership.membership_roles.find_or_create_by!(role: "administrator")

  customer = Customer.find_or_create_by!(organization: organization, name: "Indústria ABC")
  betim = Site.find_or_create_by!(organization: organization, customer: customer, name: "Betim Plant")
  contagem = Site.find_or_create_by!(organization: organization, customer: customer, name: "Contagem Plant")

  Asset.find_or_create_by!(organization: organization, site: betim, name: "Motor M-21") do |asset|
    asset.asset_type = "motor"
    asset.tag = "M-21"
    asset.manufacturer = "WEG"
  end
  Asset.find_or_create_by!(organization: organization, site: betim, name: "QGBT-01") do |asset|
    asset.asset_type = "electrical_panel"
    asset.tag = "QGBT-01"
  end
  Asset.find_or_create_by!(organization: organization, site: contagem, name: "Transformer TR-02") do |asset|
    asset.asset_type = "transformer"
    asset.tag = "TR-02"
  end
end
