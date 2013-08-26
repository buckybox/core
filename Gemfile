source 'https://rubygems.org'

gem 'rails',                      '~> 3.2.14'
gem 'pg',                         '~> 0.14.0'
gem 'haml-rails',                 '~> 0.3.4'
gem 'jquery-rails',               '~> 2.3.0'
gem 'jquery-ui-rails',            '~> 4.0.3'
gem 'bootstrap-sass',             '~> 2.3.2.0'
gem 'select2-rails',              '~> 3.4.3'
gem 'json',                       '~> 1.7.7'
gem 'devise',                     '~> 2.2.4'
gem 'multi_json',                 '~> 1.3.6'
gem 'simple_form',                '~> 2.1.0'
gem 'inherited_resources',        '~> 1.3.1'
gem 'mini_magick',                '~> 3.4'
gem 'carrierwave',                '~> 0.6.2'
gem 'money-rails',                '~> 0.5.0'
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
gem 'delayed-plugins-airbrake'              # Notify Airbrake when delayed_job has an error
gem 'daemons',                    '~> 1.1.9' # able to monitor delayed_job via monit
gem 'analytical',                 '~> 3.0.12'
gem 'newrelic_rpm',               '~> 3.6.1'
gem 'airbrake',                   '~> 3.1.2'
gem 'intercom-rails',             '~> 0.2.21'
gem 'intercom',                   '~> 0.1.11'
gem 'ace-rails-ap',               '~> 2.0.0'
gem 'activemerchant',             '~> 1.32.1'
gem 'attr_encryptor',             '~> 1.0.2'
gem 'countries',                  '~> 0.9.2', require: 'iso3166'
gem 'country_select',             '~> 1.1.3'
gem 'biggs',                      '~> 0.3.3'

gem 'charlock_holmes',            '~> 0.6.9.4'

########## THE GEMS ABOVE ARE THE ONLY ONES THAT RUN ON PRODUCTION ##########

group :assets do
  gem 'coffee-rails',   '~> 3.2.2'
  gem 'uglifier',       '~> 1.2.7'
  gem 'sass-rails',     '~> 3.2.5'
  gem 'compass-rails',  '~> 1.0.3'
end

group :install do
  gem 'sprinkle',  github: 'jordandcarter/sprinkle' # patched to be awesome.. added more verifiers and updated some installers
end

group :development do
  gem 'yard',       require: false

  gem 'bullet',     require: false
  gem 'brakeman',   require: false
  gem 'xray-rails', require: false
  gem 'ruby-prof',  require: false # profiling with /newrelic

  gem 'capistrano'
  gem 'term-ansicolor'

  gem 'guard-rspec'
  gem 'parallel_tests'

  # Pry: IRB + ruby debug alternative which is active and easier to install
  gem 'pry-rails'
  gem 'pry-debugger'
  gem 'pry-coolline'
  gem 'pry-stack_explorer'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'meta_request'

  gem 'webrick' # Included explicitly so #chunked warnings no longer show up in the dev log
end

group :test do
  gem 'fabrication'
  gem 'database_cleaner'
  gem 'therubyracer', require: false # embeded JS interpreter for our CI server

  gem 'cucumber-rails', require: false

  gem 'capybara', require: false
  gem 'capybara-screenshot'

  gem 'poltergeist', require: false
  gem 'launchy'

  gem 'fuubar', '~> 1.0.0' # 1.1.1 is broken

  gem 'bundler-audit', require: false
end

group :staging do
  gem 'mail_safe'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'guard'
  gem 'listen'

  gem 'letter_opener'

  gem 'simplecov', require: false
end

group :development, :staging do
  gem 'oink',  require: 'oink'
end

group :development, :test, :staging do
  gem 'delorean'
end
