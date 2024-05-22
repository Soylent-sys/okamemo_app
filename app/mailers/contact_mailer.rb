class ContactMailer < ApplicationMailer
  def send_contact_mail
    @contact = params[:contact]
    mail(from: "おかメchan お問い合わせフォーム <no-reply@okamemo.com>", to: ENV['CONTACT_EMAIL'], subject: "【お問い合わせ】#{@contact.subject}")
  end
end
