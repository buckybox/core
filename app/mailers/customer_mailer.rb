class CustomerMailer < ApplicationMailer
  def login_details(customer)
    @distributor = customer.distributor
    @customer = customer

    set_locale(@customer)

    mail to: @customer.email_to,
         from: @distributor.email_from(email: Figaro.env.no_reply_email),
         reply_to: @distributor.email_from,
         subject: t('customer_mailer.login_details.subject', distributor: @distributor.name)
  end

  def orders_halted(customer)
    @distributor = customer.distributor
    @customer = customer

    set_locale(@customer)

    mail to: @customer.email_to,
         from: @distributor.email_from(email: Figaro.env.no_reply_email),
         reply_to: @distributor.email_from,
         cc: @distributor.support_email,
         subject: t('customer_mailer.orders_halted.subject', distributor: @distributor.name)
  end

  def remind_orders_halted(customer)
    @distributor = customer.distributor
    @customer = customer

    set_locale(@customer)

    mail to: @customer.email_to,
         from: @distributor.email_from(email: Figaro.env.no_reply_email),
         reply_to: @distributor.email_from,
         cc: @distributor.support_email,
         subject: t('customer_mailer.remind_orders_halted.subject', distributor: @distributor.name)
  end

  def order_confirmation(order)
    @order = order.decorate
    @distributor = @order.distributor.decorate
    @customer = @order.customer.decorate

    set_locale(@customer)

    cc = @distributor.email_from if @distributor.email_distributor_on_new_webstore_order

    mail to: @customer.email_to,
         from: @distributor.email_from(email: Figaro.env.no_reply_email),
         reply_to: @distributor.email_from,
         cc: cc,
         bcc: "ced@buckybox.com", # FIXME
         subject: t('customer_mailer.order_confirmation.subject', distributor: @distributor.name)
  end

  def email_template(recipient, email)
    distributor = if recipient.respond_to? :distributor
      recipient.distributor
    else
      recipient
    end

    mail to: recipient.email_to,
         from: distributor.email_from(email: Figaro.env.no_reply_email),
         reply_to: distributor.email_from,
         subject: email.subject do |format|
          format.text { render text: email.body }
          format.html { render text: simple_format(email.body) }
         end
  end

private

  def set_locale(customer)
    I18n.locale = customer.locale
  end
end
