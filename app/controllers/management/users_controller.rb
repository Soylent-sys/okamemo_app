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
  end

  private

  def user_params
    params.require(:user).permit(:admin, :name, :email, :password, :password_confirmation)
  end
end
