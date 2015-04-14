source "https://rubygems.org"

if RUBY_VERSION != "2.1.6"
  warn "WARNING: You are not running the version of Ruby targeted for this application (#{RUBY_VERSION} != 2.1.6)."
end

group :default do # XXX: all environments, think twice before adding Gems here
  gem "rake",                            "~> 10.3.2" # i18n-spec breaks with 10.4 :/
  gem "rails",                           "~> 3.2.21"
  gem "rails-i18n",                      "~> 3.0.0" # For Rails 3.x
  gem "pg",                              "~> 0.17.0"
  gem "haml-rails",                      "~> 0.3.4"
  gem "jquery-rails",                    "~> 3.0.4"
  gem "jquery-ui-rails",                 "~> 4.0.5"
  gem "bootstrap-sass",                  "~> 2.3.2.2"
  gem "bootbox-rails",                   "~> 0.1.0"
  gem "select2-rails",                   "~> 3.5.0"
  gem "devise",                          "~> 3.2.2"
  gem "devise-i18n",                     "~> 0.10.3"
  gem "simple_form",                     "~> 2.1.1"
  gem "inherited_resources",             "~> 1.3.1"
  gem "mini_magick",                     "~> 3.4"
  gem "carrierwave",                     "~> 0.6.2"
  gem "acts-as-taggable-on",             "~> 2.3.3"
  gem "pg_search",                       "~> 0.5.1"
  gem "whenever",                        "~> 0.7.3"
  gem "acts_as_list",                    "~> 0.1.8"
  gem "default_value_for",               "~> 2.0.1"
  gem "fuzzy-string-match",              "~> 0.9.4", require: "fuzzystringmatch" # This performs fuzzy matching on the import script
  gem "state_machine",                   "~> 1.1.2"
  gem "figaro",                          "~> 0.6.4"
  gem "virtus",                          "~> 1.0.1"
  gem "draper",                          "~> 1.2.1"
  gem "naught",                          "~> 0.0.2"
  gem "premailer-rails",                 "~> 1.4.0"
  gem "nokogiri",                        "~> 1.6.2" # premailer-rails dependency
  gem "delayed_job",                     "~> 3.0.5" # send emails offline
  gem "delayed_job_active_record",       "~> 0.4.4"
  gem "delayed_job_web",                 "= 1.2.0" # version hardcoded in config/deploy.rb
  gem "daemons",                         "~> 1.1.9" # able to monitor delayed_job via monit
  gem "analytical",                      "~> 3.0.12"
  gem "ace-rails-ap",                    "~> 2.0.0"
  gem "active_utils",                    "< 3" # uninitialized constant ActiveMerchant::Billing::CreditCard::Validateable
  gem "activemerchant",                  "~> 1.32.1"
  gem "attr_encryptor",                  "~> 1.0.2"
  gem "countries",                       "~> 0.9.2", require: "iso3166"
  gem "country_select",                  "~> 1.1.3"
  gem "biggs",                           "~> 0.3.3"
  gem "charlock_holmes",                 "~> 0.6.9.4"
  gem "rabl",                            "~> 0.9.0"
  gem "apipie-rails",                    "~> 0.2.6"
  gem "strong_parameters",               "~> 0.2.1"
  gem "rails-timeago",                   "~> 2.8.1"
  gem "discover-unused-partials",        "~> 0.3.0"
  gem "rack-mini-profiler",              "~> 0.9.2"
  gem "fast_blank",                      "~> 0.0.2"
  gem "retryable",                       "~> 1.3.5"
  gem "geokit",                          "~> 1.8.5", require: false
  gem "foreman",                         ">= 0.78.0"
  gem "rails-patch-json-encode",         ">= 0.1.1"
  gem "oj",                              ">= 2.12.1"
  gem "intercom-rails",                  ">= 0.2.27"
  gem "intercom",                        ">= 2.4.4"
  gem "crazy_money",                     ">= 1.2.1"
  gem "currency_data",                   ">= 1.1.0"
  gem "email_templator",                 ">= 1.0.0"
  gem "simple_form-bank_account_number", ">= 1.0.0"
  gem "ordinalize_full",                 ">= 1.2.1", require: "ordinalize_full/integer"
  gem "librato-rails",                   ">= 0.11.1"
  gem "rbtrace",                         ">= 0.4.7"
end

group :development do
  gem "webrick" # Included explicitly so #chunked warnings no longer show up in the dev log
  gem "yard",       require: false
  gem "bullet",     require: false
  gem "brakeman",   require: false
  gem "xray-rails", require: false
  gem "ruby-prof",  require: false # profiling with /newrelic
  gem "capistrano", "~> 2" # v3 is broken with `undefined local variable or method `tasks_without_stage_dependency"` atm
  gem "term-ansicolor"
  gem "parallel_tests"
  gem "sextant"
  gem "better_errors"
  gem "binding_of_caller"
  gem "quiet_assets"
  gem "meta_request"
  gem "i15r", require: false
end

group :test do
  gem "fabrication", "~> 2.9.8" # TODO upgrade and fix broken specs
  gem "database_cleaner"
  gem "therubyracer", require: false # embeded JS interpreter for our CI server
  gem "simplecov", require: false
  gem "cucumber-rails", require: false
  gem "capybara", "~> 2.3.0", require: false # TODO: fix cukes for 2.4
  gem "capybara-screenshot"
  gem "poltergeist", require: false
  gem "launchy"
  gem "guard-rspec"
  gem "rspec-activemodel-mocks"
  gem "i18n-spec", ">= 0.5.2", require: false
end

group :staging do
  gem "mail_safe"
  # gem "oink",                            "~> 0.10.1"
end

group :staging, :production do
  gem "newrelic_rpm",                    ">= 3.9.7.266"
  gem "bugsnag",                         ">= 2.8.4"
  gem "skylight",                        ">= 0.6.0"
end

group :development, :staging do
  # gem "stackprof", git: "https://github.com/tmm1/stackprof.git"
end

group :development, :test do
  gem "rspec-rails"
  gem "listen"
  gem "terminal-notifier-guard" # Mac 10.8 system notifications for Guard
  gem "letter_opener"
  gem "bundler-audit", require: false
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
  gem "coffee-rails",   "~> 3.2.2"
  gem "uglifier",       "~> 1.2.7"
  gem "sass-rails",     "~> 3.2.5"
  gem "compass-rails",  "~> 1.0.3"
end

group :install do
  gem "sprinkle",  git: "https://github.com/jordandcarter/sprinkle.git" # patched to be awesome.. added more verifiers and updated some installers
end

