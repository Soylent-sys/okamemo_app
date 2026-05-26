# Preview all emails at http://localhost:80/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def send_contact_mail
    contact = Contact.new(
      name: "テストユーザー",
      email: "test_user@example.com",
      subject: "お問い合わせメールのプレビュー",
      message: "お問い合わせフォームから入力された内容が管理者に送信されたメールに反映されているかテストする"
    )
    ContactMailer.with(contact: contact).send_contact_mail
  end
end
