# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run BuckyBox::Application

unless Rails.env.development?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    username == Figaro.env.delayed_job_username && password == Figaro.env.delayed_job_password
  end
end
