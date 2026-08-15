class MaterialsUsedController < TechnicalRecordsController
  private

  def model_class = MaterialUsed
  def association_name = :materials_used
  def param_key = :material_used
  def record_params = params.require(:material_used).permit(:description, :quantity, :unit)

  def apply_defaults
    @technical_record.quantity = 1
    @technical_record.unit = "piece"
  end
end
