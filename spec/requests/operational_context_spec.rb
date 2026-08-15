require "rails_helper"

RSpec.describe "Customer, site, and asset management", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def member_with_role(role, organization: create(:organization))
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  def expect_denied(path)
    get path
    expect(response).to redirect_to(organization_selection_path)
  end

  def create_motor(customer, site)
    post customer_site_assets_path(customer, site), params: {
      asset: { name: "Motor M-21", asset_type: "motor", tag: "M-21", manufacturer: "WEG" }
    }
    Asset.last
  end

  def expect_asset_page(customer, site, asset)
    get customer_site_asset_path(customer, site, asset)
    expect(response.body).to include("Indústria ABC", "Betim Plant", "Motor M-21", "WEG")
  end

  it "completes the minimal Customer to Site to Asset workflow", :aggregate_failures do
    administrator = member_with_role("administrator")
    sign_in(administrator.user)

    post customers_path, params: { customer: { name: "Indústria ABC" } }
    customer = Customer.last
    expect(response).to redirect_to(customer_path(customer))
    expect(customer.organization).to eq(administrator.organization)

    post customer_sites_path(customer), params: { site: { name: "Betim Plant" } }
    site = Site.last
    expect(response).to redirect_to(customer_site_path(customer, site))
    expect(site.customer).to eq(customer)

    asset = create_motor(customer, site)
    expect(response).to redirect_to(customer_site_asset_path(customer, site, asset))
    expect(asset).to have_attributes(site: site, organization: administrator.organization,
                                     tag: "M-21", manufacturer: "WEG")

    expect_asset_page(customer, site, asset)
  end

  it "lists and searches only current-organization customers with aggregate counts" do
    supervisor = member_with_role("supervisor")
    customer = create(:customer, organization: supervisor.organization, name: "Indústria ABC")
    site = create(:site, customer: customer)
    create_list(:asset, 2, site: site)
    outsider = create(:customer, name: "Outside Customer")
    sign_in(supervisor.user)

    get customers_path, params: { query: "indústria" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Indústria ABC", ">1<", ">2<")
    expect(response.body).not_to include(outsider.name)
  end

  it "renders validation errors without losing nested context" do
    supervisor = member_with_role("supervisor")
    customer = create(:customer, organization: supervisor.organization)
    sign_in(supervisor.user)

    post customer_sites_path(customer), params: { site: { name: "" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(customer.name, "Name can&#39;t be blank")
  end

  it "allows Engineer to read but not create or edit operational context" do
    engineer = member_with_role("engineer")
    customer = create(:customer, organization: engineer.organization)
    sign_in(engineer.user)

    get customer_path(customer)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Edit customer", "Add site")

    get new_customer_site_path(customer)
    expect(response).to redirect_to(organization_selection_path)

    patch customer_path(customer), params: { customer: { name: "Changed" } }
    expect(response).to redirect_to(organization_selection_path)
    expect(customer.reload.name).not_to eq("Changed")
  end

  it "denies Technician organization-wide visibility until assignment scoping exists" do
    technician = member_with_role("technician")
    customer = create(:customer, organization: technician.organization)
    sign_in(technician.user)

    get customers_path
    expect(response).to redirect_to(organization_selection_path)

    get customer_path(customer)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "denies cross-organization direct and nested URLs without mutating records" do
    administrator = member_with_role("administrator")
    own_customer = create(:customer, organization: administrator.organization)
    foreign_customer = create(:customer)
    foreign_site = create(:site, customer: foreign_customer)
    foreign_asset = create(:asset, site: foreign_site)
    original_name = foreign_asset.name
    sign_in(administrator.user)

    expect_denied(customer_path(foreign_customer))
    expect_denied(customer_site_path(own_customer, foreign_site))
    expect_denied(customer_site_asset_path(own_customer, foreign_site, foreign_asset))

    patch customer_site_asset_path(foreign_customer, foreign_site, foreign_asset),
          params: { asset: { name: "Leaked update" } }
    expect(response).to redirect_to(organization_selection_path)
    expect(foreign_asset.reload.name).to eq(original_name)
  end

  it "renders the workflow in Brazilian Portuguese" do
    administrator = member_with_role("administrator")
    sign_in(administrator.user)
    patch locale_path, params: { locale: "pt-BR" }

    get customers_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Clientes", "Novo cliente", "Nenhum cliente ainda")
  end
end
