source "https://rubygems.org"

group :default do # XXX: all environments, think twice before adding Gems here
  gem "rake"
  gem "test-unit" # for Ruby 2.2
  gem "unicorn"
  gem "rails",                           "~> 3.2.22"
  gem "sprockets",                       "~> 2.2.3" # https://groups.google.com/forum/#!topic/rubyonrails-security/doAVp0YaTqY
  gem "rails-i18n",                      "~> 3.0.0" # For Rails 3.x
  gem "actionpack-action_caching" # until we remove `caches_action`
  gem "protected_attributes" # until we remove all `attr_accessible`
  gem "pg"
  gem "therubyracer"
  gem "haml-rails"
  gem "jquery-rails"
  gem "jquery-ui-rails",                 "< 5" # TODO: make sure JQuery UI 1.11 works fine
  gem "bootstrap-sass",                  "< 3"
  gem "bootbox-rails"
  gem "select2-rails"
  gem "hiredis"
  gem "readthis"
  gem "devise"
  gem "devise-i18n"
  gem "simple_form", "< 3"
  gem "inherited_resources"
  gem "mini_magick", "< 4"
  gem "carrierwave"
  gem "acts-as-taggable-on"
  gem "pg_search"
  gem "whenever"
  gem "acts_as_list"
  gem "default_value_for"
  gem "state_machine"
  gem "figaro"
  gem "virtus"
  gem "draper", "< 2" # Rails 3.2 not supported with v2
  gem "naught"
  gem "premailer-rails"
  gem "nokogiri" # premailer-rails dependency
  gem "delayed_job"
  gem "delayed_job_active_record"
  gem "delayed_job_web", "1.2.10" # version hardcoded in Chef repo
  gem "daemons" # able to monitor delayed_job via monit
  gem "analytical"
  gem "ace-rails-ap"
  gem "active_utils"
  gem "activemerchant"
  gem "countries", require: "iso3166"
  gem "country_select", "~> 1.1.3" # TODO: https://github.com/stefanpenner/country_select/blob/master/UPGRADING.md
  gem "biggs"
  gem "charlock_holmes"
  gem "rabl", git: "https://github.com/nesquena/rabl.git" # TODO: remove when https://github.com/nesquena/rabl/commit/e07c83d41caf1ccbbe952cbe817734af68613c4e is released
  gem "apipie-rails", "0.3.3" # 0.3.4 is broken https://github.com/Apipie/apipie-rails/pull/350
  gem "strong_parameters"
  gem "rails-timeago"
  gem "discover-unused-partials"
  gem "rack-mini-profiler"
  gem "fast_blank"
  gem "retryable"
  gem "foreman"
  gem "rails-patch-json-encode"
  gem "oj"
  gem "intercom-rails"
  gem "intercom", "~> 2"
  gem "crazy_money"
  gem "currency_data"
  gem "email_templator"
  gem "simple_form-bank_account_number"
  gem "ordinalize_full", require: "ordinalize_full/integer"
  gem "librato-rails"
  gem "rbtrace"
  gem "geokit"
  gem "typhoeus"
  gem "rack-cors"
  gem "marginalia"
end

group :development do
  gem "webrick" # Included explicitly so #chunked warnings no longer show up in the dev log
  gem "yard",       require: false
  gem "brakeman",   require: false
  gem "xray-rails", require: false
  gem "ruby-prof",  require: false # profiling with /newrelic
  gem "term-ansicolor"
  gem "parallel_tests"
  gem "sextant"
  gem "better_errors"
  gem "binding_of_caller"
  gem "quiet_assets"
  gem "meta_request"
  gem "i15r", require: false
  gem "faker"
end

group :test do
  gem "database_cleaner"
  gem "simplecov", require: false
  gem "cucumber-rails", require: false
  gem "capybara", require: false
  gem "capybara-screenshot"
  gem "poltergeist", require: false
  gem "launchy"
  gem "guard-rspec"
  gem "i18n-spec"
  gem "rspec-activemodel-mocks"
end

group :staging do
  gem "mail_safe"
  # gem "oink"
end

group :staging, :production do
  gem "newrelic_rpm"
  gem "bugsnag"
  # gem "skylight"
end

group :development, :staging do
  # gem "stackprof", git: "https://github.com/tmm1/stackprof.git"
end

group :development, :test do
  gem "fabrication"
  gem "rspec-rails"
  gem "listen"
  gem "terminal-notifier-guard" # Mac 10.8 system notifications for Guard
  gem "letter_opener"
  gem "bundler-audit", require: false
  gem "bullet"
  gem "rubocop"
  gem "byebug"
  gem "cane"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pry-coolline" # as-you-type syntax highlighting
  gem "pry-stack_explorer"
end

group :development, :test, :staging do
  gem "delorean"
end

group :assets do
  gem "coffee-rails"
  gem "uglifier"
  gem "sass-rails"
  gem "compass-rails"
end
