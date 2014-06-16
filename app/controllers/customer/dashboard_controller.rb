class Customer::DashboardController < Customer::BaseController
  def index
    @customer       = current_customer
    @account        = @customer.account
    @address        = @customer.address
    @balance        = @customer.account.balance
    @transactions   = @customer.transactions.limit(6)
    @show_more_link = @transactions.size != @customer.transactions.count
    @distributor  = @customer.distributor
    @currency     = @distributor.currency
    @orders       = @customer.orders.active.decorate(context: { currency: @currency })
    @bank         = @distributor.bank_information.decorate(context: { customer: @customer }) if @distributor.bank_information && @distributor.payment_bank_deposit
    @paypal       = paypal_form if @distributor.payment_paypal
    @order        = @customer.orders.new

    render "index", locals: {
      update_contact_details:  Customer::Form::UpdateContactDetails.new(customer: current_customer),
      update_delivery_address: Customer::Form::UpdateDeliveryAddress.new(customer: current_customer),
      update_password:         Customer::Form::UpdatePassword.new(customer: current_customer),
    }
  end

  def box
    @box   = Box.find(params[:id])
    @order = Order.find(params[:order_id])

    respond_to do |format|
      if @box.distributor == current_customer.distributor
        format.json { render json: { order: @order, box: @box } }
      else
        format.json { render json: nil, status: :unprocessable_entity }
      end
    end
  end

private

  def paypal_form
    OpenStruct.new(
      currency: @distributor.currency,
      amount_due_without_symbol: "",
      customer_email: @customer.email,
      distributor_paypal_email: @distributor.paypal_email,
      product_name: "Account top-up",
      customer_number: @customer.formated_number,
      top_up_amount: top_up_amount,
      currency_symbol: @distributor.currency_symbol,
    ).freeze
  end

  def top_up_amount
    balance = @customer.account_balance
    balance.negative? ? balance.opposite : 25
  end
end
