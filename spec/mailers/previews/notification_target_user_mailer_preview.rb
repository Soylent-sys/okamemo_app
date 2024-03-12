# Preview all emails at http://localhost:80/rails/mailers/notification_target_user_mailer
class NotificationTargetUserMailerPreview < ActionMailer::Preview
  def send_email_confirmation
    NotificationTargetUserMailer.with(nt_user: User.master_admin_user.notification_target_users.unconfirmed.first).
      send_email_confirmation
  end
end
