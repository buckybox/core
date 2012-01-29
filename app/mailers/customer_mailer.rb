class CustomerMailer < ActionMailer::Base
  default from: "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.customer_mailer.login_details.subject
  #
  def login_details customer
    @distributor = customer.distributor
    @customer = customer

    mail to: customer.email, :subject => "Login details for #{@distributor.name}", :from => "no-reply@buckybox.com"
  end
end
