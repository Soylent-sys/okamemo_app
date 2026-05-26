# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new
  def new
    super
  end

  # POST /users/password
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.guest?
      flash[:error] = "ゲストユーザーのパスワード再設定は許可されていません。"
      redirect_to new_user_session_url
    else
      super
    end
  end

  # GET /users/password/edit?reset_password_token=abcdef
  def edit
    super
  end

  # PUT /users/password
  def update
    super
  end

  protected

  def after_resetting_password_path_for(resource)
    super(resource)
  end

  # パスワードリセットの指示を送信した後に使われるpath
  def after_sending_reset_password_instructions_path_for(resource_name)
    super(resource_name)
  end
end
