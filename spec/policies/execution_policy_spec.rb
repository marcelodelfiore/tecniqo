require "rails_helper"

RSpec.describe ExecutionPolicy do
  after { Current.reset }

  def member(role, organization:)
    membership = create(:membership, organization: organization)
    create(:membership_role, membership: membership, role: role)
    membership
  end

  it "lets administrators and supervisors manage, engineers read, and Founder administer" do
    execution = create(:execution)
    Current.organization = execution.organization
    administrator = member("administrator", organization: execution.organization)
    supervisor = member("supervisor", organization: execution.organization)
    engineer = member("engineer", organization: execution.organization)
    founder = create(:user, founder: true)

    [ administrator.user, supervisor.user, founder ].each do |user|
      expect(described_class.new(user, execution)).to be_create
    end
    expect(described_class.new(engineer.user, execution)).to be_show
    expect(described_class.new(engineer.user, execution)).not_to be_create
    expect(described_class.new(founder, execution)).not_to be_perform_event
  end

  it "lets only participating Technicians perform field actions" do
    execution = create(:execution)
    participant = member("technician", organization: execution.organization)
    unrelated = member("technician", organization: execution.organization)
    create(:execution_participant, execution: execution, membership: participant)
    Current.organization = execution.organization

    expect(described_class.new(participant.user, execution)).to be_perform_event
    expect(described_class.new(unrelated.user, execution)).not_to be_show
    expect(described_class::Scope.new(participant.user, Execution.all).resolve).to contain_exactly(execution)
  end

  it "denies cross-tenant access" do
    execution = create(:execution)
    administrator = member("administrator", organization: create(:organization))
    Current.organization = administrator.organization

    expect(described_class.new(administrator.user, execution)).not_to be_show
    expect(described_class::Scope.new(administrator.user, Execution.all).resolve).to be_empty
  end
end
