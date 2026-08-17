require "rails_helper"

RSpec.describe EngineeringReviewPolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "separates technical actions from operational visibility and supports multiple roles" do
    review = create(:engineering_review)
    Current.organization = review.organization
    engineer = member("engineer", organization: review.organization)
    administrator = member("administrator", organization: review.organization)
    supervisor_engineer = member("supervisor", organization: review.organization)
    create(:membership_role, membership: supervisor_engineer, role: "engineer")
    technician = member("technician", organization: review.organization)

    expect(described_class.new(engineer.user, review)).to be_start
    expect(described_class.new(administrator.user, review)).to be_show
    expect(described_class.new(administrator.user, review)).not_to be_start
    expect(described_class.new(supervisor_engineer.user, review)).to be_start
    expect(described_class.new(technician.user, review)).not_to be_show
  end

  it "denies cross-tenant access and allows Founder to claim explicitly" do
    review = create(:engineering_review)
    outsider = member("engineer", organization: create(:organization))
    Current.organization = outsider.organization

    expect(described_class.new(outsider.user, review)).not_to be_show
    expect(described_class::Scope.new(outsider.user, EngineeringReview.all).resolve).to be_empty

    Current.organization = review.organization
    expect(described_class.new(create(:user, founder: true), review)).to be_start
  end
end
