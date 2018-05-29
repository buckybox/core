require "secure_headers"

SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"

  # rubocop:disable Lint/PercentStringArray
  config.csp = {
    default_src: %w('none'),
    img_src: %w('self' data: *.google-analytics.com *.pingdom.net *.tile.openstreetmap.org),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com *.pingdom.net),
    style_src: %w('self' 'unsafe-inline'),
    form_action: %w('self' addons.buckybox.com www.paypal.com),
    connect_src: %w('self' api.buckybox.com *.google-analytics.com *.pingdom.net),
    frame_ancestors: %w('none'),
    report_uri: %w(https://api.buckybox.com/v1/csp-report),
  }
  # rubocop:enable Lint/PercentStringArray
end
