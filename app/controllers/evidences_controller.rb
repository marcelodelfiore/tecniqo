class EvidencesController < ApplicationController
  before_action :require_authentication
  before_action :set_work_order
  before_action :set_execution
  before_action :set_evidence, only: :original
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def create
    membership = current_membership
    evidence = @execution.evidences.new(organization: Current.organization,
                                        uploaded_by_membership: membership)
    authorize evidence
    Evidence.ingest!(execution: @execution, uploaded_by_membership: membership,
                     upload: evidence_params[:original], evidence_type: evidence_params[:evidence_type],
                     description: evidence_params[:description], captured_at: evidence_params[:captured_at])
    redirect_to execution_path, notice: t("flash.evidences.created")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to execution_path, alert: error.record.errors.full_messages.to_sentence
  end

  def original
    authorize @evidence, :download?
    send_file_headers! type: @evidence.content_type, disposition: "attachment",
                       filename: @evidence.original_filename
    response.headers["Content-Length"] = @evidence.byte_size.to_s
    self.response_body = Enumerator.new do |stream|
      @evidence.original.download { |chunk| stream << chunk }
    end
  end

  private

  def set_work_order
    @work_order = policy_scope(WorkOrder).find_by(public_identifier: params[:work_order_id])
    raise Pundit::NotAuthorizedError unless @work_order
  end

  def set_execution
    @execution = policy_scope(Execution).find_by(work_order: @work_order,
                                                  visit_number: params[:execution_id])
    raise Pundit::NotAuthorizedError unless @execution
  end

  def set_evidence
    @evidence = policy_scope(Evidence).find_by(id: params[:id], execution: @execution)
    raise Pundit::NotAuthorizedError unless @evidence
  end

  def evidence_params
    params.require(:evidence).permit(:original, :evidence_type, :description, :captured_at)
  end

  def current_membership
    Current.user.memberships.active.find_by(organization: Current.organization)
  end

  def execution_path
    work_order_execution_path(@work_order, @execution)
  end
end
