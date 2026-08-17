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

  def review_state_classes(state)
    case state
    when "approved" then "bg-emerald-100 text-emerald-800"
    when "changes_requested" then "bg-amber-100 text-amber-800"
    when "in_review" then "bg-blue-100 text-blue-800"
    else "bg-gray-100 text-gray-700"
    end
  end

  def clarification_state_classes(state)
    case state
    when "resolved" then "bg-emerald-100 text-emerald-800"
    when "responded" then "bg-blue-100 text-blue-800"
    else "bg-amber-100 text-amber-800"
    end
  end

  def clarification_target_title(target)
    case target
    when WorkOrder then t("engineering_reviews.targets.work_order")
    when Execution then t("executions.visit", number: target.visit_number)
    when Finding then t("technical_records.types.finding")
    when Measurement then t("technical_records.types.measurement")
    when ActionPerformed then t("technical_records.types.action_performed")
    when MaterialUsed then t("technical_records.types.material_used")
    when Recommendation then t("technical_records.types.recommendation")
    when Evidence then t("engineering_reviews.targets.evidence")
    end
  end

  def clarification_target_summary(target)
    case target
    when WorkOrder then target.requested_work
    when Execution then t("execution_outcomes.#{target.outcome}")
    when Measurement
      "#{t("measurement_quantities.#{target.quantity}")} — " \
        "#{decimal_measurement(target.value)} #{measurement_unit_label(target.unit)} — #{target.measurement_point}"
    when MaterialUsed
      "#{target.description} — #{decimal_measurement(target.quantity)} #{t("material_units.#{target.unit}")}"
    when Evidence then target.description.presence || target.original_filename
    else target.description
    end
  end

  def clarification_request_path_for(review, execution, target)
    new_engineering_review_clarification_request_path(
      review, execution_id: execution.id, target_type: target.class.name, target_id: target.id
    )
  end
end
