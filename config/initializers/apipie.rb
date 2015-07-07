Apipie.configure do |config|
  config.app_name                = "Bucky Box API"
  config.app_info["v1"]          = "The Bucky Box API is intended for third-party shopping carts and systems to push new customers and orders into Bucky Box. To access you must send your API-Key and API-Secret via HTTP headers. Please contact Bucky Box developer support to purchase an API key."
  config.copyright               = "&copy; #{Time.now.year} Bucky Box Limited"
  config.doc_base_url            = "/docs"
  config.default_version         = "v1"
  config.api_base_url["v1"]      = "/v1"
  config.validate                = false

  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
