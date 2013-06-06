class DistributorMailer < ActionMailer::Base
  default from: Figaro.env.support_email,
          reply_to: Figaro.env.support_email

  def update_email(email, distributor)
    @email = email
    @distributor = distributor

    mail subject: @email.subject,
         to: @distributor.email
  end

end
