require "rails_helper"

RSpec.describe EvidencePolicy do
  def context(role:, participant: false)
    organization = create(:organization)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    customer = create(:customer, organization: organization)
    site = create(:site, organization: organization, customer: customer)
    work_order = create(:work_order, organization: organization, customer: customer, site: site,
                                     service_type: create(:service_type, organization: organization))
    execution = create(:execution, organization: organization, work_order: work_order)
    create(:execution_participant, organization: organization, execution: execution,
                                   membership: membership) if participant
    evidence = execution.evidences.new(organization: organization, uploaded_by_membership: membership)
    [ organization, membership, evidence ]
  end

  it "allows a participating Technician to upload and read" do
    organization, membership, evidence = context(role: "technician", participant: true)
    Current.organization = organization
    policy = described_class.new(membership.user, evidence)

    expect(policy).to be_create
    expect(policy).to be_show
    expect(policy).to be_download
  end

  it "allows broad operational roles to read but not claim field provenance" do
    %w[administrator supervisor engineer].each do |role|
      organization, membership, evidence = context(role: role)
      Current.organization = organization
      policy = described_class.new(membership.user, evidence)

      expect(policy).to be_show
      expect(policy).not_to be_create
    end
  end

  it "does not let Founder upload unless Founder is an actual participating Technician" do
    organization, membership, evidence = context(role: "supervisor")
    membership.user.update!(founder: true)
    Current.organization = organization

    expect(described_class.new(membership.user, evidence)).not_to be_create
  end

  it "denies unrelated and cross-tenant users" do
    organization, _membership, evidence = context(role: "technician", participant: true)
    outsider = create(:membership, organization: create(:organization))
    create(:membership_role, membership: outsider, role: "technician")
    Current.organization = organization

    expect(described_class.new(outsider.user, evidence)).not_to be_show
    expect(described_class.new(outsider.user, evidence)).not_to be_create
  end
end
