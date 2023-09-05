module DeviseHelper
  def bootstrap_alert(message_type)
    case message_type
    when "alert"
      "warning"
    when "notice"
      "success"
    when "error"
      "danger"
    end
  end

  def bootstrap_alert_icon(message_type)
    case message_type
    when "alert"
      "bi-exclamation-triangle-fill"
    when "notice"
      "bi-check-circle-fill"
    when "error"
      "bi-exclamation-diamond-fill"
    end
  end
end
