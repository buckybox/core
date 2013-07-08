class DistributorMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  default from: Figaro.env.support_email,
          reply_to: Figaro.env.support_email

  def update_email(email, distributor)
    @email = email
    @distributor = distributor

    headers['X-MC-Tags'] = "distributor,bucky_update"

    mail subject: @email.subject,
         to: @distributor.email do |format|
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

    mail to: @distributor.email,
         subject: "#{@distributor.name}, welcome to Bucky Box!"
  end

end
