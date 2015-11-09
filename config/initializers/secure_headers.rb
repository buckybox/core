require "secure_headers"

SecureHeaders::Configuration.configure do |config|
  config.x_frame_options = "DENY"
  config.x_xss_protection = { value: 1, mode: "block" }
  config.csp = {
    enforce: true,
    default_src: "'none'",
    img_src: "'self' *.google-analytics.com *.pingdom.net *.pingdom.com *.intercomcdn.com *.intercom.io notify.bugsnag.com *.tile.openstreetmap.org",
    script_src: "'self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com *.pingdom.net js-agent.newrelic.com bam.nr-data.net *.intercomcdn.com *.intercom.io https://d2wy8f7a9ursnm.cloudfront.net/bugsnag-2.min.js",
    style_src: "'self' 'unsafe-inline'",
    form_action: "'self' www.paypal.com",
    connect_src: "'self' *.google-analytics.com *.intercomcdn.com *.intercom.io wss://*.intercom.io",
    frame_ancestors: "'none'",
    block_all_mixed_content: "",
    report_uri: "https://api.buckybox.com/v1/csp-report",
  }
  # config.hpkp = {
  # TODO: set up HPKP
  # }
end
