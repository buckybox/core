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

  	def internal_server_error errors
        #print errors to body 
  			render nothing: true, status: :internal_server_error, formats: :json and return
  	end

    def not_found
        render nothing: true, status: :not_found, formats: :json and return
    end
end