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

    attachments.inline["powering-local-food.png"] = \
      File.read(Rails.root.join("app/assets/images/bucky-box-powering-local-food.png"))

    attachments.inline["getting-started.png"] = \
      File.read(Rails.root.join("app/assets/images/bucky-box-getting-started.png"))

    mail to: @distributor.email_to,
         from: "Sam Rye <#{Figaro.env.support_email}>",
         subject: "#{@distributor.name}, welcome to Bucky Box!"
  end

  def bank_setup(distributor, bank_name)
    @distributor = distributor
    @bank_name = bank_name

    headers['X-MC-Tags'] = "distributor,bank_setup"

    mail to: @distributor.email_to,
         from: "Jordan Carter <#{Figaro.env.support_email}>",
         subject: "[Bucky Box] Setting up your bank feed"
  end

end
