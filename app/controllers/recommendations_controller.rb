class RecommendationsController < TechnicalRecordsController
  private

  def model_class = Recommendation
  def association_name = :recommendations
  def param_key = :recommendation
  def record_params = params.require(:recommendation).permit(:description)
end
