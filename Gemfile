source 'http://rubygems.org'

# Core
gem 'rails', '~> 3.2.6'

# Database
gem 'pg'

group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'zurb-foundation'
end

gem 'redis', '~> 2.2.1'
gem 'redis-store', '~> 1.0.0'
gem 'haml-rails'
gem 'sass-rails'
gem 'jquery-rails'

gem 'devise', '~> 1.5.3'
gem 'multi_json', '~> 1.0.4'
gem 'simple_form', '~> 1.5.2'
gem 'ice_cube', git: 'git://github.com/ootoovak/ice_cube.git' # patched to persist data (that we use) in UTC timezone
gem 'inherited_resources'
gem 'mini_magick'
gem 'carrierwave'
gem 'money'
gem 'acts-as-taggable-on', git: 'git://github.com/ootoovak/acts-as-taggable-on.git' # patched to have 255 char validation on tags
gem 'pg_search'
gem 'kaminari'
gem 'airbrake'
gem 'analytical'
gem 'postmark-rails'
gem 'whenever'
gem 'newrelic_rpm'
gem 'acts_as_list'
gem 'default_value_for'
gem 'fuzzy-string-match', require: 'fuzzystringmatch' # This performs fuzzy matching on the import script
gem 'state_machine'
gem 'chosen-rails'

group :install do
  gem 'sprinkle_packages'
end

group :development do
  gem 'bullet'
  gem 'nifty-generators', require: false

  gem 'ruby-prof' # profiling with /newrelic

  gem 'capistrano'
  gem 'capistrano_colors'
  gem 'tinder'
  gem 'term-ansicolor'
  gem 'hirb'
  gem 'wirble'
  gem 'rb-fsevent', require: false if RUBY_PLATFORM =~ /darwin/i

  gem 'guard-rspec'
  gem 'guard-spork'

  gem 'spork-rails'

  # Pry: IRB + ruby debug alternative which is active and easier to install
  gem 'pry-remote' # Needed for using pry in spork
  gem 'pry-rails'
  gem 'pry-nav'
  gem 'pry-coolline'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'guard'

  gem 'rb-inotify',  require: false
  gem 'rb-fsevent',  require: false
  gem 'rb-fchange',  require: false

  gem 'mailcatcher', require: false

  gem 'simplecov',   require: false
  gem 'delorean'
end

group :test do
  gem 'fabrication', '~> 1.4.1'
  gem 'database_cleaner'

  gem 'delorean'

  gem 'capybara'
  gem 'launchy'

  gem 'guard-rspec'
  gem 'fuubar'

  gem 'cucumber-rails', require: false
end

group :staging do
  gem 'mail_safe'
  gem 'delorean'
end
