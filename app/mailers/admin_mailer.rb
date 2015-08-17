class AdminMailer < ApplicationMailer
  include ERB::Util # to get `html_escape` helper

  def information_email(options)
    body = options.delete :body

    mail({ from: Figaro.env.support_email }.merge(options)) do |format|
      format.text { render text: body }
      format.html { render text: simple_format(html_escape(body)) }
    end
  end
end
