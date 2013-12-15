source 'https://rubygems.org'

gem 'rails',                      '~> 3.2.16'
gem 'pg',                         '~> 0.17.0'
gem 'haml-rails',                 '~> 0.3.4'
gem 'jquery-rails',               '~> 3.0.4'
gem 'jquery-ui-rails',            '~> 4.0.5'
gem 'bootstrap-sass',             '~> 2.3.2.0'
gem 'bootbox-rails',              '~> 0.1.0'
gem 'select2-rails',              '~> 3.5.0'
gem 'json',                       '~> 1.7.7'
gem 'devise',                     '~> 2.2.4'
gem 'multi_json',                 '~> 1.3.6'
gem 'simple_form',                '~> 2.1.1'
gem 'inherited_resources',        '~> 1.3.1'
gem 'mini_magick',                '~> 3.4'
gem 'carrierwave',                '~> 0.6.2'
gem 'acts-as-taggable-on',        '~> 2.3.3'
gem 'pg_search',                  '~> 0.5.1'
gem 'whenever',                   '~> 0.7.3'
gem 'acts_as_list',               '~> 0.1.8'
gem 'default_value_for',          '~> 2.0.1'
gem 'fuzzy-string-match',         '~> 0.9.4', require: 'fuzzystringmatch' # This performs fuzzy matching on the import script
gem 'state_machine',              '~> 1.1.2'
gem 'figaro',                     '~> 0.6.4'
gem 'virtus',                     '~> 0.5.5'
gem 'draper',                     '~> 1.2.1'
gem 'naught',                     '~> 0.0.2'
gem 'premailer-rails',            '~> 1.4.0'
gem 'nokogiri',                   '~> 1.6.0' # premailer-rails dependency
gem 'delayed_job',                '~> 3.0.5' # send emails offline
gem 'delayed_job_active_record',  '~> 0.4.4'
gem 'delayed_job_web',            '= 1.2.0' # version hardcoded in config/deploy.rb
gem 'delayed-plugins-airbrake',   '~> 1.0.0' # Notify Airbrake when delayed_job has an error
gem 'daemons',                    '~> 1.1.9' # able to monitor delayed_job via monit
gem 'analytical',                 '~> 3.0.12'
gem 'newrelic_rpm',               '~> 3.6.1'
gem 'airbrake',                   '~> 3.1.2'
gem 'intercom-rails',             '~> 0.2.24'
gem 'intercom',                   '~> 0.1.16'
gem 'ace-rails-ap',               '~> 2.0.0'
gem 'activemerchant',             '~> 1.32.1'
gem 'attr_encryptor',             '~> 1.0.2'
gem 'countries',                  '~> 0.9.2', require: 'iso3166'
gem 'country_select',             '~> 1.1.3'
gem 'biggs',                      '~> 0.3.3'
gem 'charlock_holmes',            '~> 0.6.9.4'
gem 'easy_money',                 '~> 1.0.0', git: 'https://github.com/buckybox/easy_money.git'
gem 'currency_data',              '~> 1.0.0', git: 'https://github.com/buckybox/currency_data.git'
gem 'simple_form-bank_account_number', '~> 1.0.0', git: 'https://github.com/buckybox/simple_form-bank_account_number.git'
gem 'rabl',                       '~> 0.9.0'
gem 'oj',                         '~> 2.1.7'
gem 'apipie-rails',               '~> 0.0.24'
gem 'strong_parameters',          '~> 0.2.1'

group :assets do
  gem 'coffee-rails',   '~> 3.2.2'
  gem 'uglifier',       '~> 1.2.7'
  gem 'sass-rails',     '~> 3.2.5'
  gem 'compass-rails',  '~> 1.0.3'
end

########## THE GEMS ABOVE ARE THE ONLY ONES THAT RUN ON PRODUCTION ##########

group :install do
  gem 'sprinkle',  git: 'https://github.com/jordandcarter/sprinkle.git' # patched to be awesome.. added more verifiers and updated some installers
end

group :development do
  gem 'webrick' # Included explicitly so #chunked warnings no longer show up in the dev log
  gem 'yard',       require: false
  gem 'bullet',     require: false
  gem 'brakeman',   require: false
  gem 'xray-rails', require: false
  gem 'ruby-prof',  require: false # profiling with /newrelic
  gem 'capistrano', '~> 2' # v3 is broken with `undefined local variable or method `tasks_without_stage_dependency'` atm
  gem 'term-ansicolor'
  gem 'parallel_tests'
  gem 'sextant'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'meta_request'
  gem 'byebug'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'pry-coolline' # as-you-type syntax highlighting
  gem 'pry-stack_explorer'
end

group :test do
  gem 'fabrication'
  gem 'database_cleaner'
  gem 'therubyracer', require: false # embeded JS interpreter for our CI server
  gem 'simplecov', require: false
  gem 'cucumber-rails', require: false
  gem 'capybara', require: false
  gem 'capybara-screenshot'
  gem 'poltergeist', require: false
  gem 'launchy'
  gem 'fuubar'
  gem 'guard', '~> 1' # v2 is broken with a version mismatch issue
  gem 'guard-rspec'
end

group :staging do
  gem 'mail_safe'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'listen'
  gem 'terminal-notifier-guard' # Mac 10.8 system notifications for Guard
  gem 'letter_opener'
  gem 'bundler-audit', require: false
end

group :development, :staging do
  gem 'oink', require: 'oink'
end

group :development, :test, :staging do
  gem 'delorean'
end
