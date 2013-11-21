class Customer::DashboardController < Customer::BaseController
  def index
    @customer     = current_customer
    @account      = @customer.account
    @address      = @customer.address
    @balance      = @customer.account.balance
    @transactions = @customer.transactions.limit(6)
    @show_more_link = @transactions.size != @customer.transactions.count
    @distributor  = @customer.distributor
    @currency     = @distributor.currency
    @orders       = @customer.orders.active.decorate(context: { currency: @currency })
    @bank         = @distributor.bank_information.try(:decorate)
    @order        = @customer.orders.new
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
end
