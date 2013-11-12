class Api::V0::CustomersController < ApplicationController
	
	def index
	    @customers = Customer.all
	    respond_to do |format|
	      format.json { render :json => @customers }
	    end
  	end
  	
end