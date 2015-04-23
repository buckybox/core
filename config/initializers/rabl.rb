require "rabl"

Rabl.configure do |config|
  config.include_json_root = false
  config.include_child_root = false
  config.raise_on_missing_attribute = true
  config.cache_sources = true
  config.view_paths = [Rails.root.join("app/views/api")]
end

