# Preview all emails at http://localhost:80/rails/mailers/shopping_record_mailer
class ShoppingRecordMailerPreview < ActionMailer::Preview
  def send_shopping_result
    user = User.master_admin_user
    ShoppingRecordMailer.with(shopping_record: user.shopping_records.first,
                              nt_user: user.notification_target_users.confirmed.first).send_shopping_result
  end
end
