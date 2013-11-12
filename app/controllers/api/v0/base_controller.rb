class Api::V0::BaseController < ApplicationController
	
	before_filter :authenticate
	layout false

	private
  	def authenticate
  		api_key = request.headers['key']
  		if api_key.nil?
    		 unauthorized
  	  else
  	  	@distributor = Distributor.find_by(api_key: api_key)
	  		if @distributor.nil?
	    		unauthorized
	    	end
	  	end
  	end

	  def unauthorized
  		render nothing: true, status: :unauthorized, formats: :json and return
  	end
end