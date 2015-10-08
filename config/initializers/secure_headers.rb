require "secure_headers"

SecureHeaders::Configuration.configure do |config|
  config.x_frame_options = "DENY"
  config.x_xss_protection = { value: 1, mode: "block" }
  config.csp = {
    enforce: false,
    default_src: "'self'",
    img_src: "'self' *.google-analytics.com *.pingdom.net",
    script_src: "'self' 'unsafe-inline' www.google-analytics.com *.pingdom.net js-agent.newrelic.com bam.nr-data.net d2wy8f7a9ursnm.cloudfront.net/bugsnag-2.min.js",
    style_src: "'self' 'unsafe-inline'",
    form_action: "'self' www.paypal.com",
    frame_ancestors: "'none'",
    block_all_mixed_content: "",
    report_uri: "https://api.buckybox.com/v1/csp-report",
  }
  # config.hpkp = {
  # TODO: set up HPKP
  # }
end
