# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_actionは以下の順番を厳守
  before_action :configure_sign_up_params, only: [:create]
  before_action :check_captcha, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    super
  end

  # GET /users/edit
  def edit
    super
  end

  # PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  # GET /users/cancel
  # 通常はサインイン後に
  # 期限切れになるセッションデータを強制的に今すぐ期限切れにします。
  # これは、ユーザーがすべての OAuth セッションデータを削除して、
  # 途中で oauth サインイン/アップをキャンセルしたい場合に便利です。
  def cancel
    super
  end

  protected

  # 許可するための追加のパラメータがある場合は、sanitizer に追加してください
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # 許可するための追加のパラメータがある場合は、sanitizer に追加してください
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :hiragana_view])
  end

  # サインアップ後に使用する path
  def after_sign_up_path_for(resource)
    super(resource)
  end

  # アクティブでないアカウントのサインアップ後に使用する path
  def after_inactive_sign_up_path_for(resource)
    super(resource)
  end

  private

  # reCAPTCHAのチェック判定と未チェック時のエラーメッセージ設定処理
  def check_captcha
    return if verify_recaptcha

    self.resource = resource_class.new sign_up_params
    resource.validate
    set_minimum_password_length
    verify_recaptcha(model: resource)
    render :new, status: :unprocessable_entity
  end
end
