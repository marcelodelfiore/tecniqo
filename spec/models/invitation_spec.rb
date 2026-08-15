require "rails_helper"

RSpec.describe Invitation, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe ".issue_for!" do
    it "stores a digest and returns the raw token" do
      invitation, raw_token = described_class.issue_for!(
        organization: create(:organization),
        email: " Invited@Example.com ",
        roles: %w[technician engineer],
        invited_by: create(:user)
      )

      expect(invitation.email).to eq("invited@example.com")
      expect(invitation.roles).to eq(%w[technician engineer])
      expect(invitation.token_digest).to eq(described_class.digest(raw_token))
    end

    it "expires after the configured lifetime" do
      freeze_time do
        invitation, = described_class.issue_for!(
          organization: create(:organization),
          email: "invited@example.com",
          roles: [ "technician" ],
          invited_by: create(:user)
        )

        expect(invitation.expires_at).to eq(described_class::TOKEN_TTL.from_now)
      end
    end

    it "revokes a previous active invitation for the same organization and email" do
      organization = create(:organization)
      inviter = create(:user)
      old_invitation, = described_class.issue_for!(
        organization: organization,
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: inviter
      )

      described_class.issue_for!(
        organization: organization,
        email: "INVITED@example.com",
        roles: [ "engineer" ],
        invited_by: inviter
      )

      expect(old_invitation.reload.revoked_at).to be_present
    end

    it "rejects empty or unknown roles" do
      attributes = {
        organization: create(:organization),
        email: "invited@example.com",
        invited_by: create(:user)
      }

      expect { described_class.issue_for!(**attributes, roles: []) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { described_class.issue_for!(**attributes, roles: [ "founder" ]) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it "enforces the role vocabulary in the database" do
      invitation = create(:invitation)

      expect do
        described_class.where(id: invitation.id).update_all(roles: [ "founder" ])
      end.to raise_error(ActiveRecord::StatementInvalid, /invitations_roles_check/)
    end
  end

  describe ".accept" do
    it "creates the user and active membership with every invited role" do
      invitation, raw_token = described_class.issue_for!(
        organization: create(:organization),
        email: "new-person@example.com",
        roles: %w[technician engineer],
        invited_by: create(:user)
      )

      accepted_invitation, user = described_class.accept(raw_token)
      membership = user.memberships.find_by!(organization: invitation.organization)

      expect(accepted_invitation).to eq(invitation)
      expect(membership).to be_active
      expect(membership.membership_roles.pluck(:role)).to match_array(%w[technician engineer])
      expect(invitation.reload.accepted_at).to be_present
    end

    it "reactivates an existing membership and preserves existing roles" do
      user = create(:user, email: "existing@example.com")
      membership = create(:membership, user: user, active: false)
      create(:membership_role, membership: membership, role: "supervisor")
      invitation, raw_token = described_class.issue_for!(
        organization: membership.organization,
        email: user.email,
        roles: [ "engineer" ],
        invited_by: create(:user)
      )

      described_class.accept(raw_token)

      expect(membership.reload).to be_active
      expect(membership.membership_roles.pluck(:role)).to match_array(%w[supervisor engineer])
      expect(invitation.reload).to be_accepted_at
    end

    it "rejects reused, expired, revoked, and invalid tokens" do
      invitation, raw_token = described_class.issue_for!(
        organization: create(:organization),
        email: "invited@example.com",
        roles: [ "technician" ],
        invited_by: create(:user)
      )
      described_class.accept(raw_token)

      expect(described_class.accept(raw_token)).to be_nil

      invitation.update!(accepted_at: nil, expires_at: 1.minute.ago)
      expect(described_class.accept(raw_token)).to be_nil

      invitation.update!(expires_at: 1.day.from_now, revoked_at: Time.current)
      expect(described_class.accept(raw_token)).to be_nil
      expect(described_class.accept("invalid")).to be_nil
    end
  end
end
