class AdminMailer < ApplicationMailer
  include ERB::Util # to get `html_escape` helper

  def information_email(options)
    body = options.delete :body

    email = mail({ from: Figaro.env.support_email }.merge(options)) do |format|
      format.text { render text: body }
      format.html { render text: simple_format(html_escape(body)) }
    end

    send_via_gmail email
  end
end
