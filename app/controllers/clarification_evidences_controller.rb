class ClarificationEvidencesController < ApplicationController
  before_action :require_authentication
  before_action :set_clarification
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def create
    authorize @clarification, :add_evidence?
    evidence = Evidence.ingest!(execution: @clarification.execution,
                                uploaded_by_membership: current_membership,
                                upload: evidence_params[:original],
                                evidence_type: evidence_params[:evidence_type],
                                description: evidence_params[:description],
                                captured_at: evidence_params[:captured_at])
    @clarification.clarification_evidences.create!(organization: Current.organization,
                                                   evidence: evidence)
    redirect_to @clarification, notice: t("flash.clarifications.evidence_added")
  rescue ActiveRecord::RecordInvalid, ArgumentError => error
    message = error.respond_to?(:record) ? error.record.errors.full_messages.to_sentence : error.message
    redirect_to @clarification, alert: message
  end

  private

  def set_clarification
    @clarification = policy_scope(ClarificationRequest).find_by(id: params[:clarification_request_id])
    raise Pundit::NotAuthorizedError unless @clarification
  end

  def evidence_params
    params.require(:evidence).permit(:original, :evidence_type, :description, :captured_at)
  end

  def current_membership
    Current.user.memberships.active.find_by(organization: Current.organization)
  end
end
