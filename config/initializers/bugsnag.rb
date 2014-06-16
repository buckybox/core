Bugsnag.configure do |config|
  config.api_key = "258d4e3e5765dc450140bf47f56ae7fd"
  config.use_ssl = true
  config.notify_release_stages = %w(production staging)
end
