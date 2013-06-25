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

end
