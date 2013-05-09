class DistributorMailer < ActionMailer::Base
  default from: "Bucky Box <support@buckybox.com>",
          reply_to: "Bucky Box <support@buckybox.com>"

  def update_email(email)
    email_addresses = Distributor.keep_updated.collect{|d| "#{d.name} <#{d.email}>"}
    @email = email

    mail subject: @email.subject,
         bcc: email_addresses
  end

end
