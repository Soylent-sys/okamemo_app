module NotificationTargetUsersHelper
  def disabled_if_limited(notification_target_users)
    if notification_target_users.count >= NotificationTargetUser::NOTIFICATION_TARGET_USER_MUXIMUM_COUNT
      "disabled"
    end
  end
end
