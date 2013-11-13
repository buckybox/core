Apipie.configure do |config|
  config.app_name                = "Bucky Box API"
  config.app_info                = "The Bucky Box API for distributors. To access you must be send your key and secret via headers with every call."
  config.copyright               = "&copy; #{Time.now.year} Bucky Box Limited"
  config.doc_base_url            = "/docs"
  config.default_version         = "v0"
  config.api_base_url["v0"]      = "/v0"
  config.validate_value          = false

  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
