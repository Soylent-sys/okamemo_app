class Management::UsersController < ApplicationController
  include Pagy::Backend

  USERS_PAGENATION_SIZE = 50

  def index
    @master_admin_user = User.master_admin_user
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(@q.result, items: USERS_PAGENATION_SIZE, size: [1, 2, 2, 1])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.skip_confirmation!
    if @user.save
      flash[:notice] = "ユーザーの登録が完了しました。"
      redirect_to management_users_url
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @master_admin_user = User.master_admin_user
    @user = User.find(params[:id])
    # マスター管理ユーザー以外の同ユーザー編集画面へのアクセス制御
    if (@user == @master_admin_user) && (current_user != @master_admin_user)
      flash[:error] = "対象のユーザーはマスター管理ユーザーのみ編集可能です。"
      redirect_to management_users_url
    end
  end

  def update
    @user = User.find(params[:id])
    @user.skip_reconfirmation!
    if @user.update(update_user_params)
      # 管理ユーザーが自分の管理権限を解除した場合は通常のメインメニューにリダイレクトする
      handle_admin_removal and return if is_current_user_and_not_admin?(@user)
      flash[:notice] = "ユーザーの更新が完了しました。"
      redirect_to management_users_url
    else
      @master_admin_user = User.master_admin_user
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    # マスター管理ユーザーアカウントの削除を制御する
    if user.master_admin_user?
      flash[:error] = "マスター管理ユーザーアカウントの削除は制限されています。"
      redirect_to management_users_url
      return
    end

    was_current_user = (current_user == user)
    user.destroy!
    if was_current_user
      # 管理ユーザーが自己アカウントを削除した場合は非ログイン時のrootにリダイレクトする
      flash[:notice] = "ログイン中の管理ユーザーが削除されました。再度登録が必要な場合は管理者に依頼してください。"
      redirect_to root_url
    else
      flash[:notice] = "ユーザーが削除されました。"
      redirect_to management_users_url
    end
  end

  private

  def user_params
    params.require(:user).permit(:admin, :name, :email, :password, :password_confirmation)
  end

  def update_user_params
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params.require(:user).permit(:admin, :name, :email, :hiragana_view)
    else
      params.require(:user).permit(:admin, :name, :email, :password, :password_confirmation, :hiragana_view)
    end
  end

  def handle_admin_removal
    flash[:notice] = "更新が完了し管理者権限が解除されました。メインメニューにリダイレクトします。"
    redirect_to root_url
  end

  def is_current_user_and_not_admin?(user)
    (user == current_user) && !user.admin?
  end
end
