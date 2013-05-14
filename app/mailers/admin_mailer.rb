class AdminMailer < ActionMailer::Base

  def preview_email(email, admin)
    @email = email
    @admin = admin

    mail to: @email.preview_email,
         from: "Bucky Box <support@buckybox.com>",
         reply_to: "Bucky Box <support@buckybox.com>",
         subject: @email.subject
  end

end
