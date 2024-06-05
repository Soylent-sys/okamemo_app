class Management::UsersController < ApplicationController
  include Pagy::Backend

  USERS_PAGENATION_SIZE = 50
  SINGLE_PAGE = 1

  def index
    @master_admin_user = User.master_admin_user
    @pagy, @users = pagy(User.all, items: USERS_PAGENATION_SIZE, size: [1, 2, 2, 1])
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
  end

  def update
  end

  def destroy
    user = User.find(params[:id])
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
end
