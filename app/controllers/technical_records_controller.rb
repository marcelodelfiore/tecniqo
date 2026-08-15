class TechnicalRecordsController < ApplicationController
  before_action :require_authentication
  before_action :set_context
  before_action :set_technical_record, only: %i[edit update destroy]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def new
    @technical_record = records.new(organization: Current.organization,
                                    recorded_by_membership: current_membership,
                                    recorded_at: Time.current)
    apply_defaults
    authorize @technical_record
    load_evidences
    render "technical_records/new"
  end

  def create
    @technical_record = records.new(record_params.merge(
      organization: Current.organization,
      recorded_by_membership: current_membership,
      recorded_at: Time.current
    ))
    authorize @technical_record
    if save_with_evidence
      redirect_to execution_path, notice: t("flash.technical_records.created",
                                            record: record_label)
    else
      load_evidences
      render "technical_records/new", status: :unprocessable_entity
    end
  end

  def edit
    authorize @technical_record
    load_evidences
    render "technical_records/edit"
  end

  def update
    authorize @technical_record
    @technical_record.assign_attributes(record_params)
    if save_with_evidence
      redirect_to execution_path, notice: t("flash.technical_records.updated",
                                            record: record_label)
    else
      load_evidences
      render "technical_records/edit", status: :unprocessable_entity
    end
  end

  def destroy
    authorize @technical_record
    if @technical_record.destroy
      redirect_to execution_path, notice: t("flash.technical_records.destroyed",
                                            record: record_label)
    else
      redirect_to execution_path, alert: @technical_record.errors.full_messages.to_sentence
    end
  end

  private

  def set_context
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order

    @execution = policy_scope(Execution).find_by(work_order: @work_order,
                                                  visit_number: params[:execution_id])
    raise Pundit::NotAuthorizedError unless @execution
  end

  def set_technical_record
    @technical_record = policy_scope(model_class).find_by(id: params[:id], execution: @execution)
    raise Pundit::NotAuthorizedError unless @technical_record
  end

  def records
    @execution.public_send(association_name)
  end

  def save_with_evidence
    model_class.transaction do
      @technical_record.save!
      @technical_record.sync_evidence_ids!(submitted_evidence_ids)
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
    @technical_record.errors.add(:evidences, :invalid) if error.is_a?(ActiveRecord::RecordNotFound)
    false
  end

  def submitted_evidence_ids
    params.fetch(param_key, {}).fetch(:evidence_ids, [])
  end

  def current_membership
    Current.user.memberships.active.find_by(organization: Current.organization)
  end

  def load_evidences
    @evidences = policy_scope(Evidence).where(execution: @execution)
                                       .includes(original_attachment: :blob)
                                       .order(:accepted_at, :id)
  end

  def execution_path
    work_order_execution_path(@work_order, @execution)
  end

  def record_label
    t("technical_records.types.#{param_key}")
  end

  def apply_defaults; end
end
