ENV["RAILS_ENV"] ||= 'test'

require 'simplecov' if ENV['COVERAGE']

# Prevent main application to eager_load in the prefork block (do not load files in autoload_paths)
# https://github.com/pluginaweek/state_machine/issues/163
require 'rails/application'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.order = 'random'

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
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
    Time.zone = BuckyBox::Application.config.time_zone
  end

  config.after(:each) do
    DatabaseCleaner.clean
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

  Devise.setup do |devise|
    devise.stretches = 0
  end
end
