class Api::V0::BaseController < ApplicationController
	
	before_filter :authenticate
	layout false

	private
  	def authenticate
  		api_key = request.headers['key']
      api_secret = request.headers['secret']
  		if api_key.nil? || api_secret.nil?
    		 unauthorized
  	  else
  	  	@distributor = Distributor.find_by(api_key: api_key)
	  		if @distributor.nil? || @distributor.api_secret != api_secret
	    		unauthorized
	    	end
	  	end
  	end

	  def unauthorized
  		render nothing: true, status: :unauthorized, formats: :json and return
  	end

  	def internal_server_error errors
  			render json: errors.to_json, status: :internal_server_error and return
  	end

    def not_found
        render nothing: true, status: :not_found, formats: :json and return
    end
end