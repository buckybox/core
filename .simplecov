SimpleCov.start 'rails' do
  minimum_coverage 70
  maximum_coverage_drop 3

  add_group "Long files" do |src_file|
    src_file.lines.count > 100
  end

  add_group "SimpleForm Inputs", "app/inputs"
  add_group "CarrierWave Uploaders", "app/uploaders"
  add_group "Webstore", "webstore"
end

# vim: ft=ruby
