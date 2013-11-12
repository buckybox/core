class Api::V0::CustomersController < Api::V0::BaseController
	
	api :GET, '/customers'
	param :email #, String, "Customer's Email Address" , required: false
	def index
		cust_email = params[:email]
		if cust_email.nil?
    	@customers = @distributor.customers
    else
    	@customers = @distributor.customers.find_by(email: cust_email) 
    end
  end

  def show
		cust_id = params[:id]
		@customer  = @distributor.customers.find_by(id: cust_id)
		if @customer.nil?
			not_found
		end
	end

	def create
		cust_fname = params[:first_name]
		cust_lname = params[:last_name]
		cust_email = params[:email]
		@customer = Customer.new email: "blah@blah"
		if @customer.save
			@customer
		else
			internal_server_error customer.errors
		end
	end

end