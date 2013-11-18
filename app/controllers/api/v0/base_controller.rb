class Api::V0::BaseController < ApplicationController

  before_filter :authenticate, :embed_options
  layout false

private

  def authenticate
    api_key = request.headers['API-Key']
    api_secret = request.headers['API-Secret']

    if api_key.nil? || api_secret.nil?
       unauthorized
    else
      @distributor = Distributor.find_by(api_key: api_key)
      if @distributor.nil? || @distributor.api_secret != api_secret
        unauthorized
      end
    end
  end

  # hash parameters (2nd+ level json is only provided when requested via ?embed={object} )
  def embed_options
    @embed = params[:embed]
    @embed = "" if @embed.nil?
  end

  def fetch_json_body
    body = request.body.read

    begin
      @json_body = JSON.parse(body)
    rescue JSON::ParserError
      render json: { message: "Invalid JSON" }, status: :unprocessable_entity and return
    end
  end

  # 401
  def unauthorized
    render json: { message: "Could not authenticate. You must set the API-Key and API-Secret headers." }, status: :unauthorized and return
  end

  # 404
  def not_found
    render json: { message: "Resource not found" }, status: :not_found and return
  end

  # 422
  def unprocessable_entity errors
    render json: { errors: errors }, status: :unprocessable_entity and return
  end

  # 500
  def internal_server_error errors
    raise "FIXME: we should never return 500"
    render json: errors.to_json, status: :internal_server_error and return
  end
end
