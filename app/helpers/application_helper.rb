module ApplicationHelper
  def application_name
    Rails.configuration.x.application_name
  end

  def flash_classes(type)
    case type.to_sym
    when :notice
      "border-emerald-200 bg-emerald-50 text-emerald-800"
    when :alert
      "border-amber-200 bg-amber-50 text-amber-800"
    else
      "border-gray-200 bg-white text-gray-800"
    end
  end

  def technical_record_form_path(work_order, execution, record)
    case record
    when Finding then record.persisted? ? work_order_execution_finding_path(work_order, execution, record) : work_order_execution_findings_path(work_order, execution)
    when Measurement then record.persisted? ? work_order_execution_measurement_path(work_order, execution, record) : work_order_execution_measurements_path(work_order, execution)
    when ActionPerformed then record.persisted? ? work_order_execution_action_performed_path(work_order, execution, record) : work_order_execution_action_performeds_path(work_order, execution)
    when MaterialUsed then record.persisted? ? work_order_execution_materials_used_path(work_order, execution, record) : work_order_execution_materials_used_index_path(work_order, execution)
    when Recommendation then record.persisted? ? work_order_execution_recommendation_path(work_order, execution, record) : work_order_execution_recommendations_path(work_order, execution)
    end
  end

  def new_technical_record_path(work_order, execution, type)
    public_send("new_work_order_execution_#{type}_path", work_order, execution)
  end

  def edit_technical_record_path(work_order, execution, record)
    helper = record.is_a?(MaterialUsed) ? :edit_work_order_execution_materials_used_path :
                                         "edit_work_order_execution_#{record.model_name.singular_route_key}_path"
    public_send(helper, work_order, execution, record)
  end

  def measurement_unit_label(unit)
    t("measurement_units.#{unit}")
  end

  def decimal_measurement(value)
    number_with_precision(value, precision: 6, strip_insignificant_zeros: true)
  end
end
