class CustomerMailer < ApplicationMailer

  def login_details(customer)
    @distributor = customer.distributor
    @customer = customer

    headers['X-MC-Tags'] = "customer,login_details,#{@distributor.name.parameterize}"

    mail to: @customer.email_to,
         from: @distributor.email_from,
         subject: "Your login details for #{@distributor.name}"
  end

  def orders_halted(customer)
    @distributor = customer.distributor
    @customer = customer
    @oops = ['Uh-oh', 'Whoops', 'Oooops'].sample

    headers['X-MC-Tags'] = "customer,orders_halted,#{@distributor.name.parameterize}"

    mail to: @customer.email_to,
         from: @distributor.email_from,
         cc: @distributor.support_email,
         subject: "#{@oops}, your #{@distributor.name} deliveries have been put on hold"
  end

  def remind_orders_halted(customer)
    @distributor = customer.distributor
    @customer = customer
    @oops = ['Uh-oh', 'Whoops', 'Oooops'].sample

    headers['X-MC-Tags'] = "customer,remind_orders_halted,#{@distributor.name.parameterize}"

    mail to: @customer.email_to,
         from: @distributor.email_from,
         cc: @distributor.support_email,
         subject: "#{@oops}, your #{@distributor.name} deliveries are on hold"
  end

  def email_template(recipient, email)
    distributor = if recipient.respond_to? :distributor
      recipient.distributor
    else
      recipient
    end

    headers['X-MC-Tags'] = "customer,email_template,#{distributor.name.parameterize}"

    mail to: recipient.email_to,
         from: distributor.email_from,
         subject: email.subject do |format|
          format.text { render text: email.body }
          format.html { render text: simple_format(email.body) }
         end
  end

  def order_confirmation(order)
    @order = order.decorate
    @distributor = @order.distributor
    @customer = @order.customer

    cc = @distributor.email_from if @distributor.email_distributor_on_new_webstore_order

    headers['X-MC-Tags'] = "customer,order_confirmation,#{@distributor.name.parameterize}"

    mail to: @customer.email_to,
         from: @distributor.email_from,
         cc: cc,
         subject: "Your #{@distributor.name} Order"
  end
end
