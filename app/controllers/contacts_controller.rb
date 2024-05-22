class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def confirm
    @contact = Contact.new(contact_params)
    if @contact.valid?
      render 'confirm', status: :see_other
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def back
    @contact = Contact.new(contact_params)
    render 'new', status: :see_other
  end

  def done
    contact = Contact.new(contact_params)
    ContactMailer.with(contact: contact).send_contact_mail.deliver_now
    render 'done', status: :see_other
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
