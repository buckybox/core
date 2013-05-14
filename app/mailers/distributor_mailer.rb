class DistributorMailer < ActionMailer::Base
  default from: "Bucky Box <support@buckybox.com>",
          reply_to: "Bucky Box <support@buckybox.com>"

  def update_email(email, distributor)
    @email = email

    mail subject: @email.subject,
         to: distributor.email
  end

end
