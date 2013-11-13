Apipie.configure do |config|
  config.app_name                = "BuckyBox API"
  config.api_base_url            = "/v0"
  config.copyright 							 = "&copy; #{Time.now.year} Bucky Box Limited"
  config.doc_base_url            = "/apipie"
  config.default_version				 = "0.0"
  config.validate_value 				 = false
  config.app_info = "The Bucky Box API for distributors. To access you must be a distributor and sent your key and secret via headers with every call."
  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end