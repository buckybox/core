Apipie.configure do |config|
  config.app_name                = "Bucky Box API"
  config.app_info["v0"]          = "The Bucky Box API. To access you must send your API-Key and API-Secret via HTTP headers."
  config.copyright               = "&copy; #{Time.now.year} Bucky Box Limited"
  config.doc_base_url            = "/docs"
  config.default_version         = "v0"
  config.api_base_url["v0"]      = "/v0"
  config.validate                = false

  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
