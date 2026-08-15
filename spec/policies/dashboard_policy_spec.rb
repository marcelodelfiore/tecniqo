require "rails_helper"

RSpec.describe DashboardPolicy do
  after { Current.reset }

  it "allows an active member in the selected organization" do
    membership = create(:membership)
    Current.organization = membership.organization

    expect(described_class.new(membership.user, :dashboard)).to be_show
  end

  it "denies an inactive member" do
    membership = create(:membership, active: false)
    Current.organization = membership.organization

    expect(described_class.new(membership.user, :dashboard)).not_to be_show
  end

  it "denies a member of a different organization" do
    membership = create(:membership)
    Current.organization = create(:organization)

    expect(described_class.new(membership.user, :dashboard)).not_to be_show
  end

  it "denies access without a selected organization" do
    expect(described_class.new(create(:user), :dashboard)).not_to be_show
  end

  it "allows a Founder when an organization is selected" do
    Current.organization = create(:organization)

    expect(described_class.new(create(:user, founder: true), :dashboard)).to be_show
  end
end
