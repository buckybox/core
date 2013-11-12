Apipie.configure do |config|
  config.app_name                = "BuckyBox"
  config.api_base_url            = "/v0"
  config.doc_base_url            = "/apipie"
  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/*.rb"
end
