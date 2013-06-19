class AdminMailer < ActionMailer::Base

  def preview_email(email, admin)
    @email = email
    @admin = admin

    headers['X-MC-Tags'] = "admin,preview,#{admin.email.parameterize}"

    mail to: @email.preview_email,
         from: Figaro.env.support_email,
         reply_to: Figaro.env.support_email,
         subject: @email.subject
  end

end
