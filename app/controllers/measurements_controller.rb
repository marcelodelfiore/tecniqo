class MeasurementsController < TechnicalRecordsController
  private

  def model_class = Measurement
  def association_name = :measurements
  def param_key = :measurement
  def record_params = params.require(:measurement).permit(:quantity, :value, :unit, :measurement_point)

  def apply_defaults
    @technical_record.quantity = "voltage"
    @technical_record.unit = Measurement::DEFAULT_UNITS.fetch("voltage")
  end
end
