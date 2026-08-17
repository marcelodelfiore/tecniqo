class ClarificationRequestsController < ApplicationController
  TARGET_MODELS = {
    "Finding" => Finding,
    "Measurement" => Measurement,
    "ActionPerformed" => ActionPerformed,
    "MaterialUsed" => MaterialUsed,
    "Recommendation" => Recommendation,
    "Evidence" => Evidence
  }.freeze

  before_action :require_authentication
  before_action :set_review, only: %i[new create]
  before_action :set_clarification, only: %i[show update resolve]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def new
    @execution = review_execution
    @target = clarification_target(@execution)
    @clarification = @review.clarification_requests.new(
      organization: Current.organization, execution: @execution, target: @target,
      requested_by: Current.user, requested_at: Time.current,
      recipient_membership: default_recipient(@target, @execution)
    )
    authorize @clarification
    @recipients = eligible_recipients(@execution)
  end

  def create
    @execution = review_execution
    @target = clarification_target(@execution)
    recipient = eligible_recipients(@execution).find_by(id: clarification_params[:recipient_membership_id])
    raise Pundit::NotAuthorizedError unless recipient

    candidate = @review.clarification_requests.new(organization: Current.organization,
                                                    execution: @execution, target: @target)
    authorize candidate
    clarification = ClarificationRequest.request!(review: @review, execution: @execution,
                                                  target: @target, recipient_membership: recipient,
                                                  question: clarification_params[:question],
                                                  actor: Current.user)
    redirect_to engineering_review_path(@review, anchor: "clarification-#{clarification.id}"),
                notice: t("flash.clarifications.created")
  rescue ActiveRecord::RecordInvalid => error
    @clarification = error.record.is_a?(ClarificationRequest) ? error.record : candidate
    @recipients = eligible_recipients(@execution)
    render :new, status: :unprocessable_content
  end

  def show
    authorize @clarification
    @work_order = @clarification.engineering_review.work_order
    @available_evidences = policy_scope(Evidence).where(execution: @clarification.execution)
                                                 .includes(original_attachment: :blob)
                                                 .order(:accepted_at, :id)
  end

  def update
    authorize @clarification, :respond?
    @clarification.respond!(actor_membership: current_membership,
                            response: response_params[:response],
                            evidence_ids: response_params[:evidence_ids])
    redirect_to @clarification, notice: t("flash.clarifications.responded")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
    @work_order = @clarification.engineering_review.work_order
    @available_evidences = policy_scope(Evidence).where(execution: @clarification.execution)
    @clarification.errors.add(:evidences, :invalid) if error.is_a?(ActiveRecord::RecordNotFound)
    render :show, status: :unprocessable_content
  end

  def resolve
    authorize @clarification
    @clarification.resolve!(actor: Current.user)
    redirect_to engineering_review_path(@clarification.engineering_review,
                                        anchor: "clarification-#{@clarification.id}"),
                notice: t("flash.clarifications.resolved")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to engineering_review_path(@clarification.engineering_review),
                alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_review
    @review = policy_scope(EngineeringReview).find_by(id: params[:engineering_review_id])
    raise Pundit::NotAuthorizedError unless @review
  end

  def set_clarification
    @clarification = policy_scope(ClarificationRequest).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @clarification
  end

  def review_execution
    @review.executions.find_by(id: params[:execution_id]) || raise(Pundit::NotAuthorizedError)
  end

  def clarification_target(execution)
    type = params[:target_type].to_s
    id = params[:target_id]
    case type
    when "WorkOrder" then @review.work_order if id.to_i == @review.work_order_id
    when "Execution" then execution if id.to_i == execution.id
    when *TARGET_MODELS.keys
      TARGET_MODELS.fetch(type).where(execution: execution).find_by(id: id)
    end || raise(Pundit::NotAuthorizedError)
  end

  def eligible_recipients(execution)
    execution.participant_memberships.active.joins(:membership_roles)
             .where(membership_roles: { role: "technician" }).includes(:user).distinct
  end

  def default_recipient(target, execution)
    membership = if target.respond_to?(:recorded_by_membership)
      target.recorded_by_membership
    elsif target.respond_to?(:uploaded_by_membership)
      target.uploaded_by_membership
    end
    membership || execution.participant_memberships.first
  end

  def clarification_params
    params.expect(clarification_request: %i[question recipient_membership_id])
  end

  def response_params
    params.expect(clarification_request: [ :response, { evidence_ids: [] } ])
  end

  def current_membership
    Current.user.memberships.active.find_by(organization: Current.organization)
  end
end
