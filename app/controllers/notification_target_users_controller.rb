class NotificationTargetUsersController < ApplicationController
  before_action :authenticate_user!, except: :confirm_email

  def index
    @notification_target_users = current_user.notification_target_users.old_created
  end

  def new
    @notification_target_user = NotificationTargetUser.new
  end

  def create
    @notification_target_user = NotificationTargetUser.new(notification_target_user_params)
    if @notification_target_user.save
      NotificationTargetUserMailer.with(nt_user: @notification_target_user).send_email_confirmation.deliver_later
      flash[:notice] = "登録したメールアドレスへ確認メールを送信しました。確認メールの認証の有効期限は10分です。"
      redirect_to notification_target_users_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def resend_email_confirmation
    @notification_target_user = current_user.notification_target_users.find_by_hashid(params[:hashid])
    if @notification_target_user.blank?
      flash[:error] = "登録された通知対象ユーザー以外へのメール送信処理はできません。"
      redirect_to notification_target_users_url
      return
    end

    if @notification_target_user.confirmed?
      flash[:error] = "#{@notification_target_user.email} は既にメール認証済みです。"
      redirect_to notification_target_users_url
      return
    end

    if @notification_target_user.expired?
      @notification_target_user.reset_email_confirmation
      NotificationTargetUserMailer.with(nt_user: @notification_target_user).send_email_confirmation.deliver_later
      flash[:notice] = "#{@notification_target_user.email} へ確認メールを再送信しました。確認メールの認証の有効期限は10分です。"
      redirect_to notification_target_users_url
    else
      flash[:error] = "確認メールの有効期限が切れる前に再送信することはできません。"
      redirect_to notification_target_users_url
    end
  end

  def confirm_email
    @notification_target_user = NotificationTargetUser.find_by(confirmation_token: params[:token])
    if @notification_target_user.blank?
      flash[:error] = "メールアドレス認証以外でのアクセスは禁止されています。"
      redirect_to root_url
      return
    end

    unless @notification_target_user.expired?
      @notification_target_user.activate
    end
  end

  def destroy
    notification_target_user = current_user.notification_target_users.find_by_hashid!(params[:hashid])
    notification_target_user.destroy!
    flash[:notice] = "通知対象ユーザーが削除されました。"
    redirect_to notification_target_users_url
  end

  private

  def notification_target_user_params
    params.require(:notification_target_user).permit(:name, :email).merge(user_id: current_user.id)
  end
end
