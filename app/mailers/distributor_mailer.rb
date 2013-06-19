class DistributorMailer < ActionMailer::Base
  default from: Figaro.env.support_email,
          reply_to: Figaro.env.support_email

  def update_email(email, distributor)
    @email = email
    @distributor = distributor

    headers['X-MC-Tags'] = "distributor,bucky_update"

    mail subject: @email.subject,
         to: @distributor.email
  end

end
