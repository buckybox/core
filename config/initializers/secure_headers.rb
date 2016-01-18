require "secure_headers"

SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_xss_protection = "1; mode=block"
  config.csp = {
    enforce: true,
    default_src: %w('none'),
    img_src: %w('self' *.google-analytics.com *.pingdom.net *.pingdom.com *.intercomcdn.com *.intercomassets.com *.intercom.io *.tile.openstreetmap.org),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com *.pingdom.net js-agent.newrelic.com bam.nr-data.net *.intercomcdn.com *.intercom.io),
    style_src: %w('self' 'unsafe-inline'),
    form_action: %w('self' www.paypal.com),
    connect_src: %w('self' api.buckybox.com *.google-analytics.com *.intercomcdn.com *.intercom.io wss://*.intercom.io),
    frame_ancestors: %w('none'),
    block_all_mixed_content: '',
    report_uri: %w(https://api.buckybox.com/v1/csp-report),
  }
  # config.hpkp = {
  # TODO: set up HPKP
  # }
end
