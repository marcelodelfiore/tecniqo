class EngineeringReviewsController < ApplicationController
  before_action :require_authentication
  before_action :set_review, only: %i[show start approve]
  after_action :verify_policy_scoped
  after_action :verify_authorized

  def index
    authorize EngineeringReview
    @reviews = policy_scope(EngineeringReview)
               .includes(work_order: %i[customer site asset service_type executions])
               .order(Arel.sql("CASE state WHEN 'changes_requested' THEN 0 WHEN 'pending' THEN 1 " \
                               "WHEN 'in_review' THEN 2 ELSE 3 END"), updated_at: :desc)
  end

  def show
    authorize @review
    load_story
  end

  def start
    authorize @review
    @review.start!(actor: Current.user)
    redirect_to @review, notice: t("flash.engineering_reviews.started")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @review, alert: error.record.errors.full_messages.to_sentence
  end

  def approve
    authorize @review
    @review.approve!(actor: Current.user)
    redirect_to @review, notice: t("flash.engineering_reviews.approved")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to @review, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def set_review
    @review = policy_scope(EngineeringReview).find_by(id: params[:id])
    raise Pundit::NotAuthorizedError unless @review
  end

  def load_story
    @work_order = @review.work_order
    @executions = @review.executions.includes(
      :execution_events,
      :evidences,
      execution_participants: { membership: :user },
      findings: { evidence_references: { evidence: { original_attachment: :blob } } },
      measurements: { evidence_references: { evidence: { original_attachment: :blob } } },
      action_performeds: { evidence_references: { evidence: { original_attachment: :blob } } },
      materials_used: { evidence_references: { evidence: { original_attachment: :blob } } },
      recommendations: { evidence_references: { evidence: { original_attachment: :blob } } }
    ).order(:visit_number)
    @clarifications = policy_scope(ClarificationRequest).where(engineering_review: @review)
                                                          .includes(:requested_by, :resolved_by,
                                                                    recipient_membership: :user,
                                                                    responded_by_membership: :user,
                                                                    evidences: { original_attachment: :blob })
                                                          .order(:requested_at, :id)
  end
end
