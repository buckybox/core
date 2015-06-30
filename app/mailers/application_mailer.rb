class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  default 'X-Mailer' => Figaro.env.x_mailer

protected

  def send_via_gmail(email)
    email.delivery_method.settings.merge!(
      address:              Figaro.env.gmail_smtp_host,
      port:                 Figaro.env.gmail_smtp_port,
      user_name:            Figaro.env.gmail_smtp_user_name,
      password:             Figaro.env.gmail_smtp_password,
      authentication:       Figaro.env.gmail_smtp_authentication,
      enable_starttls_auto: Figaro.env.gmail_smtp_enable_starttls_auto,
    )

    email
  end
end
