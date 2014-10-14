class Api::V1::BaseController < ApplicationController
  layout false
  before_filter :authenticate, :set_locale, :embed_options

private

  def api_key
    request.headers['API-Key']
  end

  def api_secret
    request.headers['API-Secret']
  end

  def webstore_id
    request.headers['Webstore-ID']
  end

  def authenticate
    if api_key.blank? || api_secret.blank?
      send_alert_email
      render json: { message: "Could not authenticate. You must set the API-Key and API-Secret headers." }, status: :unauthorized and return
    end

    if webstore_id
      if api_key == Figaro.env.api_master_key && api_secret == Figaro.env.api_master_secret
        @distributor = Distributor.find_by(parameter_name: webstore_id)
      else
        send_alert_email
        render json: { message: "Could not authenticate. Invalid master API-Key or API-Secret headers." }, status: :unauthorized and return
      end
    else
      @distributor = Distributor.find_by(api_key: api_key, api_secret: api_secret)
    end

    if !@distributor
      return not_found
    end
  end

  def set_locale
    I18n.locale = @distributor.locale
  end

  def send_alert_email
    AdminMailer.information_email(
      to: "sysalerts@buckybox.com",
      subject: "[URGENT] Hacking attempt!",
      body: "Hacking attempt detected on the API!"
    ).deliver
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

  # 404
  def not_found
    render json: { message: "Resource not found" }, status: :not_found and return
  end

  # 422
  def unprocessable_entity errors
    render json: { errors: errors }, status: :unprocessable_entity and return
  end
end
