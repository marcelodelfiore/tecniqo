require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:user) { build(:user) }
  let(:record) { Object.new }

  it "denies every standard action by default" do
    decisions = %i[index? show? create? new? update? edit? destroy?].map { |action| policy.public_send(action) }

    expect(decisions).to all(be(false))
  end

  it "rejects an unauthenticated actor" do
    expect { described_class.new(nil, record) }.to raise_error(Pundit::NotAuthorizedError)
  end

  describe ApplicationPolicy::Scope do
    it "returns no records by default" do
      visible_user = create(:user)

      expect(described_class.new(user, User.all).resolve).not_to include(visible_user)
    end

    it "rejects an unauthenticated actor" do
      expect { described_class.new(nil, User.all) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
