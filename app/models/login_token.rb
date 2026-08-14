class LoginToken < ApplicationRecord
  TOKEN_TTL = 15.minutes

  belongs_to :user

  validates :token_digest, :expires_at, presence: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user)
    record = nil
    raw_token = SecureRandom.urlsafe_base64(32)

    user.with_lock do
      revoke_active_tokens_for!(user)
      record = user.login_tokens.create!(
        token_digest: digest(raw_token),
        expires_at: TOKEN_TTL.from_now
      )
    end

    [ record, raw_token ]
  end

  def self.find_active(raw_token)
    return if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.consume(raw_token)
    return nil if raw_token.blank?

    transaction do
      record = lock.find_by(token_digest: digest(raw_token))
      return unless record && record.used_at.nil? && !record.expired?

      record.update!(used_at: Time.current)
      record
    end
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def self.revoke_active_tokens_for!(user)
    user.login_tokens.active.update_all(
      used_at: Time.current
    )
  end

  def used?
    used_at.present?
  end

  def expired?
    expires_at <= Time.current
  end
end
