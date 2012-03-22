ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

counter = -1

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false

  config.include Delorean
  config.include Devise::TestHelpers,       type: :controller
  config.include Devise::ControllerHelpers, type: :controller
  config.include Devise::RequestHelpers,    type: :request

  config.extend Devise::ControllerMacros, type: :controller
  config.extend Devise::RequestMacros,    type: :request

  config.before(:suite) do
    GC.disable
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
    Time.zone = BuckyBox::Application.config.time_zone
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:each) do
    counter += 1
    if counter > 15
      GC.enable
      GC.start
      GC.disable
      counter = 0
    end
  end

  config.after(:suite) do
    counter = 0
  end

  # Don't need passwords in test DB to be secure, but we would like 'em to be
  # fast -- and the stretches mechanism is intended to make passwords
  # computationally expensive.
  module Devise
    module Models
      module DatabaseAuthenticatable
        protected

        def password_digest(password)
          password
        end
      end
    end
  end
  Devise.setup do |config|
    config.stretches = 0
  end
end
