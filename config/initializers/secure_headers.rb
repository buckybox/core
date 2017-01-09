require "secure_headers"

SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"

  # rubocop:disable Lint/PercentStringArray
  config.csp = {
    default_src: %w('none'),
    img_src: %w('self' data: *.google-analytics.com *.pingdom.net *.pingdom.com *.intercomcdn.com *.intercomassets.com *.intercom.io *.tile.openstreetmap.org),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com *.pingdom.net *.intercomcdn.com *.intercom.io),
    style_src: %w('self' 'unsafe-inline'),
    form_action: %w('self' addons.buckybox.com www.paypal.com),
    connect_src: %w('self' api.buckybox.com *.google-analytics.com *.intercomcdn.com *.intercom.io wss://*.intercom.io),
    media_src: %w(*.intercomcdn.com),
    font_src: %w(*.intercomcdn.com),
    frame_ancestors: %w('none'),
    report_uri: %w(https://api.buckybox.com/v1/csp-report),
  }
  # rubocop:enable Lint/PercentStringArray
end
