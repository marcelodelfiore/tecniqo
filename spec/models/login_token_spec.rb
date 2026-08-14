require 'rails_helper'

RSpec.describe LoginToken, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with user, token_digest, and expires_at' do
      login_token = build(:login_token)

      expect(login_token).to be_valid
    end

    it 'is invalid without token_digest' do
      login_token = build(:login_token, token_digest: nil)

      expect(login_token).not_to be_valid
      expect(login_token.errors[:token_digest]).to include("can't be blank")
    end

    it 'is invalid without expires_at' do
      login_token = build(:login_token, expires_at: nil)

      expect(login_token).not_to be_valid
      expect(login_token.errors[:expires_at]).to include("can't be blank")
    end
  end

  describe '.digest' do
    it 'returns a sha256 hex digest' do
      raw_token = 'my-raw-token'
      expected = Digest::SHA256.hexdigest(raw_token)

      expect(described_class.digest(raw_token)).to eq(expected)
    end
  end

  describe '.issue_for!' do
    it 'creates a login token for the user' do
      user = create(:user)

      expect do
        described_class.issue_for!(user)
      end.to change(user.login_tokens, :count).by(1)
    end

    it 'returns the persisted token record and raw token' do
      user = create(:user)

      login_token, raw_token = described_class.issue_for!(user)

      expect(login_token).to be_persisted
      expect(raw_token).to be_present
      expect(login_token.token_digest).to eq(described_class.digest(raw_token))
    end

    it 'sets expires_at using TOKEN_TTL' do
      user = create(:user)

      freeze_time do
        login_token, = described_class.issue_for!(user)

        expect(login_token.expires_at).to eq(described_class::TOKEN_TTL.from_now)
      end
    end

    it 'revokes previously active tokens for the user' do
      user = create(:user)
      old_token = create(:login_token, user: user, used_at: nil, expires_at: 10.minutes.from_now)

      freeze_time do
        described_class.issue_for!(user)

        expect(old_token.reload.used_at).to eq(Time.current)
      end
    end

    it 'does not revoke already used tokens again' do
      user = create(:user)
      used_at = 5.minutes.ago
      old_token = create(:login_token, user: user, used_at: used_at, expires_at: 10.minutes.from_now)

      described_class.issue_for!(user)

      expect(old_token.reload.used_at.to_i).to eq(used_at.to_i)
    end
  end

  describe '.consume' do
    it 'returns nil when raw_token is blank' do
      expect(described_class.consume(nil)).to be_nil
      expect(described_class.consume('')).to be_nil
      expect(described_class.consume('   ')).to be_nil
    end

    it 'returns the token record when the token is valid' do
      user = create(:user)
      login_token, raw_token = described_class.issue_for!(user)

      consumed = described_class.consume(raw_token)

      expect(consumed).to eq(login_token)
    end

    it 'marks the token as used when consumed' do
      user = create(:user)
      _login_token, raw_token = described_class.issue_for!(user)

      freeze_time do
        consumed = described_class.consume(raw_token)

        expect(consumed.reload.used_at).to eq(Time.current)
      end
    end

    it 'returns nil for an invalid token' do
      expect(described_class.consume('invalid-token')).to be_nil
    end

    it 'returns nil for an expired token' do
      user = create(:user)
      login_token, raw_token = described_class.issue_for!(user)
      login_token.update!(expires_at: 1.minute.ago)

      expect(described_class.consume(raw_token)).to be_nil
    end

    it 'returns nil for a previously used token' do
      user = create(:user)
      _login_token, raw_token = described_class.issue_for!(user)

      described_class.consume(raw_token)

      expect(described_class.consume(raw_token)).to be_nil
    end
  end

  describe '.revoke_active_tokens_for!' do
    it 'marks active tokens as used' do
      user = create(:user)
      active_token_1 = create(:login_token, user: user, used_at: nil, expires_at: 10.minutes.from_now)
      active_token_2 = create(:login_token, user: user, used_at: nil, expires_at: 20.minutes.from_now)

      freeze_time do
        described_class.revoke_active_tokens_for!(user)

        expect(active_token_1.reload.used_at).to eq(Time.current)
        expect(active_token_2.reload.used_at).to eq(Time.current)
      end
    end

    it 'does not touch expired or already used tokens' do
      user = create(:user)
      expired_token = create(:login_token, user: user, used_at: nil, expires_at: 1.minute.ago)
      used_token = create(:login_token, user: user, used_at: 2.minutes.ago, expires_at: 10.minutes.from_now)

      described_class.revoke_active_tokens_for!(user)

      expect(expired_token.reload.used_at).to be_nil
      expect(used_token.reload.used_at.to_i).to eq(2.minutes.ago.to_i)
    end
  end

  describe '.active' do
    it 'includes unused, unexpired tokens' do
      user = create(:user)
      active_token = create(:login_token, user: user, used_at: nil, expires_at: 10.minutes.from_now)

      expect(described_class.active).to include(active_token)
    end

    it 'excludes used tokens' do
      user = create(:user)
      used_token = create(:login_token, user: user, used_at: Time.current, expires_at: 10.minutes.from_now)

      expect(described_class.active).not_to include(used_token)
    end

    it 'excludes expired tokens' do
      user = create(:user)
      expired_token = create(:login_token, user: user, used_at: nil, expires_at: 1.minute.ago)

      expect(described_class.active).not_to include(expired_token)
    end
  end

  describe '#used?' do
    it 'returns true when used_at is present' do
      login_token = build(:login_token, used_at: Time.current)

      expect(login_token.used?).to be(true)
    end

    it 'returns false when used_at is nil' do
      login_token = build(:login_token, used_at: nil)

      expect(login_token.used?).to be(false)
    end
  end

  describe '#expired?' do
    it 'returns true when expires_at is in the past' do
      login_token = build(:login_token, expires_at: 1.minute.ago)

      expect(login_token.expired?).to be(true)
    end

    it 'returns false when expires_at is in the future' do
      login_token = build(:login_token, expires_at: 10.minutes.from_now)

      expect(login_token.expired?).to be(false)
    end
  end
end
