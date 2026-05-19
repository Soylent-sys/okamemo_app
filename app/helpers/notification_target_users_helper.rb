module NotificationTargetUsersHelper
  # 通知ユーザーの最大登録数に達している場合は登録ボタンを非活性にする
  def disabled_if_limited(notification_target_users)
    if notification_target_users.size >= NotificationTargetUser::NOTIFICATION_TARGET_USER_MUXIMUM_COUNT
      "disabled"
    end
  end
end
