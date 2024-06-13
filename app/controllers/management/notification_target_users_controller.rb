class Management::NotificationTargetUsersController < ApplicationController
  include Pagy::Backend

  NT_USERS_PAGENATION_SIZE = 50

  def index
    @pagy, @notification_target_users = pagy(NotificationTargetUser.all, items: NT_USERS_PAGENATION_SIZE, size: [1, 2, 2, 1])
  end

  def new
    @notification_target_user = NotificationTargetUser.new
  end

  def create
    @notification_target_user = NotificationTargetUser.new(notification_target_user_params)
    if @notification_target_user.save
      flash[:notice] = "通知ユーザーの登録が完了しました。"
      redirect_to management_notification_target_users_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    notification_target_user = NotificationTargetUser.find(params[:id])
    notification_target_user.destroy!
    flash[:notice] = "通知ユーザーが削除されました。"
    redirect_to management_notification_target_users_url
  end

  private

  def notification_target_user_params
    params.require(:notification_target_user).permit(:user_id, :name, :email, :confirmation_status)
  end
end
