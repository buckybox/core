require "secure_headers"

SecureHeaders::Configuration.configure do |config|
  config.x_frame_options = "DENY"
  config.x_xss_protection = { value: 1, mode: "block" }
  config.csp = {
    enforce: false,
    default_src: "'none'",
    img_src: "'self' *.google-analytics.com *.pingdom.net *.intercomcdn.com",
    script_src: "'self' 'unsafe-inline' *.google-analytics.com *.pingdom.net js-agent.newrelic.com bam.nr-data.net js.intercomcdn.com widget.intercom.io https://d2wy8f7a9ursnm.cloudfront.net/bugsnag-2.min.js",
    style_src: "'self' 'unsafe-inline'",
    form_action: "'self' www.paypal.com",
    connect_src: "'self' *.google-analytics.com *.intercom.io wss://*.intercom.io",
    frame_ancestors: "'none'",
    block_all_mixed_content: "",
    report_uri: "https://api.buckybox.com/v1/csp-report",
  }
  # config.hpkp = {
  # TODO: set up HPKP
  # }
end
