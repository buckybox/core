Apipie.configure do |config|
  config.app_name                = "BuckyBox API"
  config.api_base_url            = "/v0"
  config.doc_base_url            = "/apipie"
  config.default_version				 = "0.0"
  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
