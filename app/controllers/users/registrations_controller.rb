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
    @master_admin_user = User.master_admin_user
    super
  end

  # PUT /users
  def update
    # update失敗時editのrender前に@master_admin_userを読み込むためsuperをオーバーライド
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      @master_admin_user = User.master_admin_user
      respond_with resource
    end
  end

  # DELETE /users
  def destroy
    # マスター管理ユーザーアカウントの削除を制御する
    if (current_user == resource) && resource.master_admin_user?
      flash[:error] = "マスター管理ユーザーアカウントの削除は制限されています。"
      redirect_to edit_user_registration_path
    else
      super
    end
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
