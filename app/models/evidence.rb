class Evidence < ApplicationRecord
  class ImmutableOriginalError < StandardError; end
  TYPES = %w[photo thermogram audio video document technical_file other].freeze
  CONTENT_TYPES = {
    "photo" => %w[image/jpeg image/png image/webp image/heic image/heif],
    "thermogram" => %w[image/jpeg image/png image/webp application/octet-stream],
    "audio" => %w[audio/mp4 audio/aac audio/webm audio/wav audio/x-wav],
    "video" => %w[video/mp4 video/quicktime video/webm],
    "document" => %w[application/pdf],
    "technical_file" => %w[text/plain text/csv application/octet-stream],
    "other" => %w[image/jpeg image/png image/webp application/pdf text/plain text/csv]
  }.freeze
  MAX_BYTES = {
    "photo" => 25.megabytes, "thermogram" => 100.megabytes,
    "audio" => 100.megabytes, "video" => 500.megabytes,
    "document" => 25.megabytes, "technical_file" => 100.megabytes,
    "other" => 25.megabytes
  }.freeze

  belongs_to :organization
  belongs_to :execution
  belongs_to :uploaded_by_membership, class_name: "Membership"
  has_one_attached :original
  has_many :evidence_references, dependent: :restrict_with_exception

  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :evidence_type, inclusion: { in: TYPES }
  validates :original_filename, :content_type, :integrity_digest, :accepted_at, presence: true
  validates :byte_size, numericality: { only_integer: true, greater_than: 0 }
  validates :integrity_algorithm, inclusion: { in: %w[SHA-256] }
  validates :integrity_digest, format: { with: /\A[0-9a-f]{64}\z/ }
  validate :original_is_attached
  validate :tenant_relationships_are_consistent
  validate :uploader_is_participating_technician
  validate :supported_original
  validate :accepted_record_is_immutable, on: :update

  before_destroy :prevent_destruction

  attr_readonly :organization_id, :execution_id, :uploaded_by_membership_id, :evidence_type,
                :description, :captured_at, :original_filename, :content_type, :byte_size,
                :integrity_algorithm, :integrity_digest, :accepted_at

  def original=(attachable)
    raise ImmutableOriginalError, "accepted evidence original cannot be replaced" if persisted? && original.attached?

    super
  end

  def self.ingest!(execution:, uploaded_by_membership:, upload:, evidence_type:, description: nil,
                   captured_at: nil)
    raise ArgumentError, "upload is required" unless upload

    evidence = new(organization: execution.organization, execution: execution,
                   uploaded_by_membership: uploaded_by_membership, evidence_type: evidence_type,
                   description: description, captured_at: captured_at, accepted_at: Time.current)
    integrity_digest = sha256_for_upload(upload)
    evidence.original.attach(upload)
    blob = evidence.original.blob
    evidence.assign_attributes(original_filename: blob.filename.to_s, content_type: blob.content_type,
                               byte_size: blob.byte_size, integrity_digest: integrity_digest)
    evidence.save!
    evidence
  rescue StandardError
    blob&.purge if blob&.persisted? && !blob.attachments.exists?
    raise
  end

  def self.sha256_for_upload(upload)
    io = upload.respond_to?(:tempfile) ? upload.tempfile : upload.fetch(:io)
    digest = Digest::SHA256.new
    while (chunk = io.read(5.megabytes))
      digest.update(chunk)
    end
    io.rewind
    digest.hexdigest
  end
  private_class_method :sha256_for_upload

  private

  def original_is_attached
    errors.add(:original, :blank) unless original.attached?
  end

  def tenant_relationships_are_consistent
    errors.add(:execution, :invalid) if execution && execution.organization_id != organization_id
    if uploaded_by_membership && uploaded_by_membership.organization_id != organization_id
      errors.add(:uploaded_by_membership, :invalid)
    end
  end

  def uploader_is_participating_technician
    return unless execution && uploaded_by_membership
    return if uploaded_by_membership.active? &&
              uploaded_by_membership.membership_roles.exists?(role: "technician") &&
              execution.participant?(uploaded_by_membership)

    errors.add(:uploaded_by_membership, :invalid)
  end

  def supported_original
    return unless evidence_type.in?(TYPES) && content_type && byte_size

    errors.add(:content_type, :invalid) unless content_type.in?(CONTENT_TYPES.fetch(evidence_type))
    if byte_size > MAX_BYTES.fetch(evidence_type)
      errors.add(:byte_size, :less_than_or_equal_to, count: MAX_BYTES.fetch(evidence_type))
    end
  end

  def accepted_record_is_immutable
    errors.add(:base, :evidence_immutable) if changes_to_save.except("updated_at").present?
  end

  def prevent_destruction
    errors.add(:base, :evidence_immutable)
    throw :abort
  end
end
