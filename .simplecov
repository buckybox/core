SimpleCov.start 'rails' do
  add_group "Long files" do |src_file|
    src_file.lines.count > 100
  end

  add_group "Decorators", "app/decorators"
  add_group "SimpleForm Inputs", "app/inputs"
  add_group "CarrierWave Uploaders", "app/uploaders"
  add_group "Webstore", "webstore"
end

# vim: ft=ruby
