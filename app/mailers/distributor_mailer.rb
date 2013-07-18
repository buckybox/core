class DistributorMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  default from: "Bucky Box Support <#{Figaro.env.support_email}>"

  def update_email(email, distributor)
    @email = email
    @distributor = distributor

    headers['X-MC-Tags'] = "distributor,bucky_update"

    mail subject: @email.subject,
         to: @distributor.email_to do |format|
          format.text { render text: @email.mail_merge(@distributor) }
          format.html { render text: simple_format(@email.mail_merge(@distributor)) }
         end
  end

  def welcome(distributor)
    @distributor = distributor

    headers['X-MC-Tags'] = "distributor,welcome"

    mail to: @distributor.email_to,
         from: "Sam Rye <#{Figaro.env.support_email}>",
         subject: "#{@distributor.name}, welcome to Bucky Box!"
  end

  def bank_setup(distributor, bank_name)
    @distributor = distributor
    @bank_name = bank_name

    headers['X-MC-Tags'] = "distributor,bank_setup"

    message = mail to: @distributor.email_to,
         from: "Jordan Carter <#{Figaro.env.support_email}>",
         subject: "[Bucky Box] Setting up your bank feed"

    message.delivery_method.settings.merge!(
      address: Figaro.env.gmail_smtp_host,
      port: Figaro.env.gmail_smtp_port,
      user_name: Figaro.env.gmail_smtp_user_name,
      password: Figaro.env.gmail_smtp_password
    )

    message
  end

end
