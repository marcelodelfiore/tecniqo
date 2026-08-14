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
end
