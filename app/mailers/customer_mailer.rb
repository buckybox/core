class CustomerMailer < ActionMailer::Base
  default from: "no-reply@buckybox.com"

  def login_details customer
    @distributor = customer.distributor
    @customer = customer

    mail to: @customer.email,
         from: "#{@distributor.name} <no-reply@buckybox.com>",
         reply_to: @distributor.support_email,
         subject: "Your Login details for #{@distributor.name}"
  end

  #TODO we are not doing invoicing at the moment
  def invoice invoice
    #@invoice = invoice
    #@account = invoice.account
    #@customer = @account.customer
    #@distributor = @account.distributor

    #mail to: @customer.email,
      #reply_to: @distributor.support_email,
      #subject: "Your #{@distributor.name} Bill/Account Statement ##{@invoice.number}"
  end
end
