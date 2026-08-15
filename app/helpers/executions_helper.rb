module ExecutionsHelper
  def duration_label(seconds)
    return t("executions.durations.unavailable") if seconds.nil?

    total_minutes = (seconds / 60).round
    hours, minutes = total_minutes.divmod(60)
    return t("executions.durations.minutes", count: minutes) if hours.zero?
    return t("executions.durations.hours", count: hours) if minutes.zero?

    t("executions.durations.hours_minutes", hours: hours, minutes: minutes)
  end

  def execution_state_classes(state)
    case state
    when "working" then "bg-green-100 text-green-800"
    when "paused" then "bg-amber-100 text-amber-800"
    when "submitted" then "bg-blue-100 text-blue-800"
    when "unable_to_execute" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-700"
    end
  end
end
