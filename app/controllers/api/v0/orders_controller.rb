class Api::V0::OrdersController < Api::V0::BaseController

	def_param_group :order do
		param :order, Hash, "Json object representing the new order", required: true do
			param :box_id, Integer, "ID of the box", required: true
			param :customer_id, String, "The customer's ID. If you don't have this refer to customer API."
		end
	end

	api :GET, '/orders',  "Get list of orders"
	param :customer_id, String, desc: "Customer's id. Selects orders for that customer."
=begin
	param :date_from, String, desc: "Starting unix timestamp of a date range."
	param :date_to, String, desc: "Ending unix timestamp of a date range."
=end	
	example "/orders/?customer_id=123"  
	def index
		cust_id = params[:customer_id]
		if cust_id.nil?
    	@orders = @distributor.orders
    else
    	@orders = @distributor.customers.orders.all 
    end
  end

  api :GET, '/orders/:id', "Get single order"
  param :id, Integer, desc: "Order's id"
  example "api.buckybox.com/v0/orders/12"
  def show
  	order_id = params[:id]
  	@order = @distributor.orders.find_by(id: order_id)

  	return not_found if @order.nil?
  	account = Account.find(@order.account_id)
  	return not_found if account.nil?
  	@customer_id = account.customer_id
  end


  api :POST, '/orders',  "Create a new order"
	description 'Currently all orders are quantity of 1 for only 1 box. For now, post a new order for every box and every quantity.'
	example '{
    "order": {
        "box_id": 12,
        "customer_id": 123
    }
}'
	param_group :order
	def create
		new_order = params[:order]
		return internal_server_error if new_order.nil?
		new_order = JSON.parse new_order
		customer = @distributor.customers.find_by(id: new_order['order']['customer_id'])
		return internal_server_error if customer.nil?

		@order = Order.new
		@order.account = Account.find_by(customer_id: customer.id)
		@order.box_id = new_order['order']['box_id']
		@customer_id = @order.account.customer_id
		if @order.save
			render 'api/v0/orders/create', status: :created, location: api_v0_order_url(id: @order.id) and return
		else
			return internal_server_error @order.errors
		end
	end

end
