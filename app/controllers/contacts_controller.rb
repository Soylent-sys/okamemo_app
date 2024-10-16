class ContactsController < ApplicationController
  def new
    if user_signed_in?
      @contact = Contact.new(name: current_user.name, email: current_user.email)
    else
      @contact = Contact.new
    end
  end

  def confirm
    @contact = Contact.new(contact_params)
    # ゲストユーザーのお問い合わせは受け付けない
    if current_user&.guest?
      flash.now[:error] = "ゲストユーザーからのお問い合わせは受け付けておりません。ログアウトして再度お問い合わせフォームからご利用ください。"
      render 'new', status: :unprocessable_entity
      return
    end

    if recaptcha_presence_check_and_valid(@contact)
      # see_otherステータスコードのrenderは以下のメソッドで実行する
      render_with_status_see_other 'confirm'
    else
      set_error_message(@contact) unless user_signed_in?
      render 'new', status: :unprocessable_entity
    end
  end

  def back
    @contact = Contact.new(contact_params)
    # see_otherステータスコードのrenderは以下のメソッドで実行する
    render_with_status_see_other 'new'
  end

  def done
    contact = Contact.new(contact_params)
    ContactMailer.with(contact: contact).send_contact_mail.deliver_now
    # see_otherステータスコードのrenderは以下のメソッドで実行する
    render_with_status_see_other 'done'
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end

  # サインインしていない場合はバリデーションに加えてrecaptchaをチェックする
  def recaptcha_presence_check_and_valid(contact)
    if user_signed_in?
      contact.valid?
    else
      contact.valid? && verify_recaptcha
    end
  end

  # recaptchaチェックされていない場合contactモデルエラーにrecaptchaエラーを追加する
  def set_error_message(contact)
    contact.valid?
    verify_recaptcha(model: contact)
  end
end
