class WorkOrder < ApplicationRecord
  PRIORITIES = %w[normal high urgent].freeze

  belongs_to :organization
  belongs_to :customer
  belongs_to :site
  belongs_to :asset, optional: true
  belongs_to :service_type
  belongs_to :created_by, class_name: "User"

  has_many :assignments, -> { order(assigned_at: :desc) }, dependent: :restrict_with_exception,
                                                               inverse_of: :work_order
  has_one :current_assignment, -> { where(ended_at: nil) }, class_name: "Assignment",
                                                          inverse_of: :work_order
  has_many :executions, -> { order(:visit_number) }, dependent: :restrict_with_exception
  has_one :engineering_review, dependent: :restrict_with_exception

  normalizes :requested_work, with: ->(value) { value.to_s.strip.presence }

  validates :sequence_number, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :organization_id }
  validates :public_identifier, presence: true, uniqueness: { scope: :organization_id }
  validates :requested_work, presence: true
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validate :relationships_belong_to_organization
  validate :asset_belongs_to_site
  validate :approved_technical_context_is_unchanged, on: :update

  def self.issue!(organization:, attributes:, created_by:, assignee_membership: nil)
    transaction do
      organization.lock!
      sequence_number = organization.work_order_sequence + 1
      organization.update!(work_order_sequence: sequence_number)

      work_order = create!(attributes.merge(
        organization: organization,
        created_by: created_by,
        sequence_number: sequence_number,
        public_identifier: format("OS-%<year>d-%<number>06d", year: Time.current.year, number: sequence_number)
      ))
      work_order.assign_to!(assignee_membership, assigned_by: created_by) if assignee_membership
      work_order
    end
  end

  def assign_to!(membership, assigned_by:)
    with_lock do
      validate_assignee!(membership)
      current = current_assignment
      return current if current&.membership_id == membership.id

      timestamp = Time.current
      current&.end_at!(timestamp)
      assignment = assignments.create!(organization: organization, membership: membership,
                                       assigned_by: assigned_by, assigned_at: timestamp)
      association(:current_assignment).reset
      assignment
    end
  end

  def to_param
    public_identifier
  end

  def execution_creation_available?
    previous = executions.order(visit_number: :desc).first
    previous.nil? || (previous.submitted? && previous.outcome == "return_required")
  end

  def ready_for_engineering_review?
    visits = Execution.where(work_order: self).order(:visit_number).to_a
    visits.any? && visits.all?(&:submitted?) && visits.last.outcome != "return_required"
  end

  private

  def relationships_belong_to_organization
    { customer: customer, site: site, asset: asset, service_type: service_type }.each do |name, related|
      next if related.nil? || organization.nil? || related.organization_id == organization_id

      errors.add(name, :invalid)
    end
    errors.add(:site, :invalid) if site && customer && site.customer_id != customer_id
  end

  def asset_belongs_to_site
    errors.add(:asset, :invalid) if asset && site && asset.site_id != site_id
  end

  def validate_assignee!(membership)
    return if membership&.active? && membership.organization_id == organization_id &&
              membership.membership_roles.exists?(role: "technician")

    errors.add(:assignments, :invalid_assignee)
    raise ActiveRecord::RecordInvalid, self
  end

  def approved_technical_context_is_unchanged
    return unless engineering_review&.state == "approved"
    return if changes_to_save.except("updated_at").empty?

    errors.add(:base, :technical_content_approved)
  end
end
