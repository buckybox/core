class AdminMailer < ActionMailer::Base

  include ActionView::Helpers::TextHelper

  def preview_email(email, admin)
    @email = email
    @admin = admin

    headers['X-MC-Tags'] = "admin,preview,#{@email.preview_email.parameterize}"

    mail to: @email.preview_email,
         from: Figaro.env.support_email,
         reply_to: Figaro.env.support_email,
         subject: @email.subject do |format|
          format.text { render text: @email.mail_merge(@admin) }
          format.html { render text: simple_format(@email.mail_merge(@admin)) }
         end
  end

  def information_email(options)
    headers['X-MC-Tags'] = "admin,information"

    body = options.delete :body

    mail({ from: Figaro.env.no_reply_email }.merge(options)) do |format|
      format.text { render text: body }
      format.html { render text: simple_format(body) }
    end
  end

end
