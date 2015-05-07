require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(assets: %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module BuckyBox
  class Application < Rails::Application
    config.version = `git log -1 --pretty='format:%h (%ci)'` rescue '[unknown]'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(
      #{config.root}/app/models/concerns/
      #{config.root}/app/controllers/concerns/
      #{config.root}/lib/
    )

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Wellington'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    # https://github.com/svenfuchs/rails-i18n
    config.i18n.available_locales = Dir[Rails.root.join("config", "locales", "*")]
      .select { |path| File.directory? path }
      .map { |directory| File.basename directory }

    config.i18n.default_locale = :en

    # fall back to config.i18n.default_locale translation if key is missing
    config.i18n.fallbacks = true

    # http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning
    config.i18n.enforce_available_locales = true

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true
    config.sass.preferred_syntax = :sass

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :fabrication
    end

    # Dump database functions into the schema
    config.active_record.schema_format = :sql

    # CORS setup (including handling of preflight OPTIONS requests)
    config.middleware.insert_before 0, "Rack::Cors", debug: Rails.env.development? do
      allow do
        origins(/^https?:\/\/.*\.buckybox\.(com|local)(:[0-9]+)?$/)

        resource("*",
          if: lambda do |env|
            env["SERVER_NAME"] =~ /^my\.buckybox\.(com|local)$/ &&
            env["PATH_INFO"] =~ /^\/sign_up_wizard\//
          end,
          headers: nil,
          methods: %i(get post),
          credentials: true,
          max_age: 0,
        )

        resource("*",
          if: ->(env) { env["SERVER_NAME"] =~ /^api\.buckybox\.(com|local)$/ },
          headers: %w(API-Key API-Secret Webstore-ID Accept), # "Accept" is needed for Chrome
          methods: :any,
          credentials: true,
          max_age: 0,
        )
      end
    end
  end
end
