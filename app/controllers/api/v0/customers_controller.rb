class Api::V0::CustomersController < Api::V0::BaseController
	
	def index
    @customers = @distributor.customers
  end

	def create

	end

  


end