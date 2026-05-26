class NotificationTargetUserMailer < ApplicationMailer
  def send_email_confirmation
    @notification_target_user = params[:nt_user]
    mail(to: @notification_target_user.email, subject: "メールアドレス認証のお願い")
  end
end
