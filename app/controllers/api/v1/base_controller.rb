class Api::V1::BaseController < ApplicationController
  layout false
  before_action :log_request, :authenticate, :set_time_zone, :set_locale, :embed_options
  skip_before_action :authenticate, only: [:ping, :csp_report, :geoip]

  # rescue_from ActionController::RoutingError, with: :not_found # TODO: enable with Rails 4
  # rescue_from Exception, with: :server_error # TODO: enable with Rails 4

  def ping
    render text: nil, status: :no_content
  end

  def csp_report
    report = request.raw_post

    # XXX: maybe parse JSON down the road...
    # rubocop:disable Lint/PercentStringArray
    blacklist = %w(
      .tlscdn.com
      .apollocdn.com
      .akamaihd.net
      .cloudfront.net
      http://127.0.0.1
      https://nikkomsgchannel
      webviewprogressproxy://
      safari-extension://
      chrome-extension://
      chrome://
      none://
      "blocked-uri":""
      "blocked-uri":"data
    ).freeze
    # rubocop:enable Lint/PercentStringArray

    if !request.user_agent.to_s.include?("Microsoft") &&
       blacklist.none? { |pattern| report.include?(pattern) }

      Bugsnag.notify(RuntimeError.new("CSP violation"), {
                       report: report,
                       user_agent: request.user_agent,
                       ip_address: request.remote_ip,
                     })
    end

    render text: nil, status: :no_content
  end

  def geoip
    ip = params.fetch(:ip, request.remote_ip)
    geoip = Bucky::Geolocation.get_geoip_info(ip)

    return unprocessable_entity("unknown error") unless geoip

    render json: geoip.to_h
  end

private

  def log_request
    info = {
      api_key: api_key,
      webstore_id: webstore_id,
      method: request.method,
      request_path: request.fullpath,
      params: request.request_parameters,
      ip: request.remote_ip,
    }.to_json

    logger.info "API request: #{info}"

    Librato.increment "bucky.api.hit"
  end

  def authenticate
    if api_key.blank? || api_secret.blank?
      send_alert_email "Hacking attempt detected on the API from #{request.remote_ip}!"
      render json: { message: "Could not authenticate. You must set the API-Key and API-Secret headers." }, status: :unauthorized and return
    end

    if api_key == Figaro.env.api_master_key && api_secret == Figaro.env.api_master_secret
      @distributor = Distributor.find_by(parameter_name: webstore_id)
      return not_found unless @distributor
    else
      @distributor = Distributor.find_by(api_key: api_key, api_secret: api_secret)
    end

    unless @distributor
      send_alert_email "Hacking attempt detected on the API from #{request.remote_ip}!"
      render json: { message: "Could not authenticate. Invalid API-Key or API-Secret headers." }, status: :unauthorized and return
    end
  end

  def set_time_zone
    Time.zone = @distributor.time_zone if @distributor
  end

  def set_locale
    I18n.locale = @distributor.locale if @distributor
  end

  # hash parameters (2nd+ level json is only provided when requested via ?embed={object} )
  def embed_options
    @embed = params[:embed].to_s.split(",").to_set.freeze
  end

  def api_key
    request.headers['API-Key']
  end

  def api_secret
    request.headers['API-Secret']
  end

  def webstore_id
    request.headers['Webstore-ID']
  end

  def send_alert_email(body)
    AdminMailer.information_email(
      to: "sysalerts@buckybox.com",
      subject: "[URGENT] Hacking attempt!",
      body: body,
    ).deliver
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
  def unprocessable_entity(errors)
    render json: { errors: errors }, status: :unprocessable_entity and return
  end
end
