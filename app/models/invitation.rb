class Invitation < ApplicationRecord
  TOKEN_TTL = 7.days

  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, :token_digest, :expires_at, presence: true
  validate :roles_are_valid

  scope :active, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(organization:, email:, roles:, invited_by:)
    raw_token = SecureRandom.urlsafe_base64(32)
    normalized_email = email.to_s.strip.downcase
    normalized_roles = Array(roles).map(&:to_s).uniq

    transaction do
      active.where(organization: organization, email: normalized_email)
            .update_all(revoked_at: Time.current)

      invitation = create!(
        organization: organization,
        invited_by: invited_by,
        email: normalized_email,
        roles: normalized_roles,
        token_digest: digest(raw_token),
        expires_at: TOKEN_TTL.from_now
      )

      [ invitation, raw_token ]
    end
  end

  def self.find_active(raw_token)
    return if raw_token.blank?

    active.find_by(token_digest: digest(raw_token))
  end

  def self.accept(raw_token)
    return if raw_token.blank?

    transaction do
      invitation = lock.find_by(token_digest: digest(raw_token))
      return unless invitation&.active?

      user = User.find_or_create_by!(email: invitation.email)
      membership = Membership.find_or_initialize_by(
        organization: invitation.organization,
        user: user
      )
      membership.active = true
      membership.save!

      invitation.roles.each do |role|
        membership.membership_roles.find_or_create_by!(role: role)
      end

      invitation.update!(accepted_at: Time.current)

      [ invitation, user ]
    end
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  def active?
    accepted_at.nil? && revoked_at.nil? && expires_at.future?
  end

  private

  def roles_are_valid
    return if roles.present? && roles.all? { |role| MembershipRole::ROLES.include?(role) }

    errors.add(:roles, "must contain at least one valid role")
  end
end
