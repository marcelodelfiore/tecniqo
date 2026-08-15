class FindingsController < TechnicalRecordsController
  private

  def model_class = Finding
  def association_name = :findings
  def param_key = :finding
  def record_params = params.require(:finding).permit(:description, :severity)

  def apply_defaults
    @technical_record.severity = "significant"
  end
end
