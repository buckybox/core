class CustomerMailer < ActionMailer::Base
  default from: "no-reply@buckybox.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.customer_mailer.login_details.subject
  #
  def login_details customer
    @distributor = customer.distributor
    @customer = customer

    mail to: customer.email, :subject => "Login details for #{@distributor.name}"
  end

  def invoice invoice
    @invoice = invoice
    @account = invoice.account
    @customer = @account.customer
    @distributor = @account.distributor
    mail :to => @customer.email, :subject => "Your #{@distributor.name} Bill/Account Statement ##{@invoice.number}"
  end
end
