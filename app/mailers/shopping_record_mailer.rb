class ShoppingRecordMailer < ApplicationMailer
  def send_shopping_result
    @shopping_record = params[:shopping_record]
    @notification_target_user = params[:nt_user]
    mail(to: @notification_target_user.email, subject: "【お知らせ】#{@notification_target_user.user.name}さんがお買い物しました！")
  end

  class << self
    def send_shopping_result_to_notification_target_users(shopping_record)
      nt_users = shopping_record.user.notification_target_users.confirmed
      nt_users.each do |nt_user|
        ShoppingRecordMailer.with(shopping_record: shopping_record, nt_user: nt_user).send_shopping_result.deliver_later
      end
    end
  end
end
