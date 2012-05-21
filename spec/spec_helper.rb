require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  ENV["RAILS_ENV"] ||= 'test'

  require 'simplecov'
  SimpleCov.start 'rails'

  # Prevent main application to eager_load in the prefork block (do not load files in autoload_paths)
  require 'rails/application'
  Spork.trap_method(Rails::Application, :eager_load!)

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'pry-remote'

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  counter = -1

  RSpec.configure do |config|
    config.mock_with :rspec
    config.use_transactional_fixtures = false
    config.infer_base_class_for_anonymous_controllers = false

    # as per http://railscasts.com/episodes/285-spork
    config.treat_symbols_as_metadata_keys_with_true_values = true
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true

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
end

Spork.each_run do
  # This code will be run each time you run your specs.
end

# --- Instructions ---
# Sort the contents of this file into a Spork.prefork and a Spork.each_run
# block.
#
# The Spork.prefork block is run only once when the spork server is started.
# You typically want to place most of your (slow) initializer code in here, in
# particular, require'ing any 3rd-party gems that you don't normally modify
# during development.
#
# The Spork.each_run block is run each time you run your specs.  In case you
# need to load files that tend to change during development, require them here.
# With Rails, your application modules are loaded automatically, so sometimes
# this block can remain empty.
#
# Note: You can modify files loaded *from* the Spork.each_run block without
# restarting the spork server.  However, this file itself will not be reloaded,
# so if you change any of the code inside the each_run block, you still need to
# restart the server.  In general, if you have non-trivial code in this file,
# it's advisable to move it into a separate file so you can easily edit it
# without restarting spork.  (For example, with RSpec, you could move
# non-trivial code into a file spec/support/my_helper.rb, making sure that the
# spec/support/* files are require'd from inside the each_run block.)
#
# Any code that is left outside the two blocks will be run during preforking
# *and* during each_run -- that's probably not what you want.
#
# These instructions should self-destruct in 10 seconds.  If they don't, feel
# free to delete them.




