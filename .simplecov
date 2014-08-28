SimpleCov.start 'rails' do
  add_filter "/vendor/" # Gems on CI server

  add_group "Long files" do |src_file|
    src_file.lines.count > 100
  end

  add_group "Decorators", "app/decorators"
  add_group "SimpleForm Inputs", "app/inputs"
  add_group "CarrierWave Uploaders", "app/uploaders"

  minimum_coverage 80
  merge_timeout 3600
end

# vim: ft=ruby
