SimpleCov.start "rails" do
  add_filter "/vendor/"

  add_group "Decorators", "app/decorators"
  add_group "SimpleForm Inputs", "app/inputs"
  add_group "CarrierWave Uploaders", "app/uploaders"
  add_group "API", "app/controllers/api/"

  add_group "Long files" do |src_file|
    src_file.lines.count > 150
  end

  merge_timeout 3600
end

# vim: ft=ruby
