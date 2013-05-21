source 'https://rubygems.org'

# Core
gem 'rails', '~> 3.2.13'

# Database
gem 'pg', '~> 0.14.0'

gem 'haml-rails',      '~> 0.3.4'
gem 'jquery-rails',    '~> 2.1.1'
gem 'bootstrap-sass',  '~> 2.1.0.0'
gem 'select2-rails',   '~> 3.2.1'
gem 'ember-rails',     '~> 0.7.0'

gem 'json',                 '~> 1.7.7'
gem 'devise',               '~> 2.1.2'
gem 'multi_json',           '~> 1.3.6'
gem 'simple_form',          '~> 2.0.2'
gem 'inherited_resources',  '~> 1.3.1'
gem 'mini_magick',          '~> 3.4'
gem 'carrierwave',          '~> 0.6.2'
gem 'money-rails',          '~> 0.5.0'
gem 'acts-as-taggable-on',  '~> 2.3.3'
gem 'pg_search',            '~> 0.5.1'
gem 'whenever',             '~> 0.7.3'
gem 'acts_as_list',         '~> 0.1.8'
gem 'default_value_for',    '~> 2.0.1'
gem 'fuzzy-string-match',   '~> 0.9.4',  require: 'fuzzystringmatch' # This performs fuzzy matching on the import script
gem 'state_machine',        '~> 1.1.2'

gem 'postmark-rails',  '~> 0.4.1'
gem 'analytical',      '~> 3.0.12'
gem 'newrelic_rpm',    '~> 3.6.1'
gem 'airbrake',        '~> 3.1.2'

gem 'ace-rails-ap',  '~> 2.0.0'

gem 'activemerchant',  '~> 1.32.1'
gem 'attr_encryptor',  '~> 1.0.2'

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
  gem 'bullet',    require: false
  gem 'brakeman',  require: false
  gem 'xray-rails'
  gem 'ruby-prof' # profiling with /newrelic

  gem 'capistrano'
  gem 'term-ansicolor'

  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'spork-rails'

  # Pry: IRB + ruby debug alternative which is active and easier to install
  gem 'pry-rails'
  gem 'pry-debugger'
  gem 'pry-coolline'
  gem 'pry-remote' # Needed for using pry in spork

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

  gem 'capybara', require: false
  gem 'cucumber-rails', require: false
  gem 'launchy'

  gem 'fuubar'

  gem 'bundler-audit', require: false
end

group :staging do
  gem 'mail_safe'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'guard'
  gem 'listen'

  gem 'letter_opener', require: false

  gem 'simplecov', require: false
end

group :development, :staging do
  gem 'oink',  require: 'oink'
end

group :development, :test, :staging do
  gem 'delorean'
end
