module BootstrapHelper
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
      "fas fa-circle-exclamation"
    when "notice"
      "fas fa-circle-check"
    when "error"
      "fas fa-triangle-exclamation"
    end
  end
end
