require "rails_helper"

RSpec.describe "Membership management", type: :request do
  def sign_in(user)
    _login_token, raw_token = LoginToken.issue_for!(user)
    post consume_magic_session_path(token: raw_token)
  end

  def create_administrator
    membership = create(:membership)
    create(:membership_role, membership: membership, role: "administrator")
    membership
  end

  it "lists only current-organization members for an Administrator" do
    administrator = create_administrator
    colleague = create(:membership, organization: administrator.organization)
    create(:membership_role, membership: colleague, role: "technician")
    outsider = create(:membership)
    sign_in(administrator.user)

    get memberships_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(administrator.user.email, colleague.user.email)
    expect(response.body).not_to include(outsider.user.email)
  end

  it "renders role and lifecycle editing" do
    administrator = create_administrator
    member = create(:membership, organization: administrator.organization)
    create(:membership_role, membership: member, role: "technician")
    sign_in(administrator.user)

    get edit_membership_path(member)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member.user.email, "Active access", "Administrator", "Engineer")
  end

  it "updates roles and lifecycle" do
    administrator = create_administrator
    member = create(:membership, organization: administrator.organization)
    create(:membership_role, membership: member, role: "technician")
    sign_in(administrator.user)

    patch membership_path(member), params: {
      membership: { active: "0", roles: %w[supervisor engineer] }
    }

    expect(response).to redirect_to(memberships_path)
    expect(member.reload).not_to be_active
    expect(member.membership_roles.pluck(:role)).to match_array(%w[supervisor engineer])
  end

  it "prevents deactivating the last active Administrator" do
    administrator = create_administrator
    sign_in(administrator.user)

    patch membership_path(administrator), params: {
      membership: { active: "0", roles: [ "administrator" ] }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("must retain at least one active Administrator")
    expect(administrator.reload).to be_active
  end

  it "denies non-Administrators and cross-organization IDs" do
    member = create(:membership)
    create(:membership_role, membership: member, role: "technician")
    inaccessible = create(:membership)
    sign_in(member.user)

    get memberships_path
    expect(response).to redirect_to(organization_selection_path)

    delete session_path
    administrator = create_administrator
    sign_in(administrator.user)
    get edit_membership_path(inaccessible)
    expect(response).to redirect_to(organization_selection_path)
  end

  it "allows Founder within the selected organization" do
    organization = create(:organization)
    founder = create(:user, founder: true)
    member = create(:membership, organization: organization)
    sign_in(founder)

    get edit_membership_path(member)

    expect(response).to have_http_status(:ok)
  end
end
