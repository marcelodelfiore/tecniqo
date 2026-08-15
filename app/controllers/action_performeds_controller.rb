class ActionPerformedsController < TechnicalRecordsController
  private

  def model_class = ActionPerformed
  def association_name = :action_performeds
  def param_key = :action_performed
  def record_params = params.require(:action_performed).permit(:description)
end
