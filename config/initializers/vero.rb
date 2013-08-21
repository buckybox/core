Vero::App.init do |config|
  config.api_key = Figaro.env.vero_api_key
  config.secret = Figaro.env.vero_secret

  # send events asynchronously
  config.async = :delayed_job

  # use test mode on staging
  config.development_mode = !Rails.env.production?
end
