source 'http://rubygems.org'

# Core
gem 'rails', '~> 3.2.8'

# Database
gem 'pg', '~> 0.14.0'

gem 'haml-rails', '~> 0.3.4'
gem 'jquery-rails', '~> 2.0.2'
gem 'chosen-rails', '~> 0.9.8.1'

gem 'devise', '~> 2.1.2'
gem 'multi_json', '~> 1.3.6'
gem 'simple_form', '~> 2.0.2'
gem 'ice_cube', git: 'git://github.com/ootoovak/ice_cube.git' # patched to persist data (that we use) in UTC timezone
gem 'inherited_resources', '~> 1.3.1'
gem 'mini_magick', '~> 3.4'
gem 'carrierwave', '~> 0.6.2'
gem 'money-rails', '~> 0.5.0'
gem 'acts-as-taggable-on', '~> 2.3.3'
gem 'pg_search', '~> 0.5.1'
gem 'whenever', '~> 0.7.3'
gem 'acts_as_list', '~> 0.1.8'
gem 'default_value_for', '~> 2.0.1'
gem 'fuzzy-string-match', '~> 0.9.4', require: 'fuzzystringmatch' # This performs fuzzy matching on the import script
gem 'state_machine', '~> 1.1.2'

gem 'postmark-rails', '~> 0.4.1'
gem 'analytical', '~> 3.0.12'
gem 'newrelic_rpm', '~> 3.4.1'
gem 'airbrake', '~> 3.1.2'

########## THE GEMS ABOVE ARE THE ONLY ONES THAT RUN ON PRODUCTION ##########

group :assets do
  gem 'sass-rails', '~> 3.2.5'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '~> 1.2.7'
  gem 'zurb-foundation', '~> 2.2.1.2'
end

group :install do
  gem 'sprinkle_packages', '~> 0.0.1'
end

group :development do
  gem 'puma', require: false

  gem 'nifty-generators', '~> 0.4.6', require: false

  gem 'ruby-prof', '~> 0.11.2' # profiling with /newrelic

  gem 'capistrano', '~> 2.12.0'
  gem 'capistrano_colors', '~> 0.5.5'
  gem 'tinder', '~> 1.9.0'
  gem 'term-ansicolor', '~> 1.0.7'
  gem 'hirb', '~> 0.7.0'
  gem 'wirble', '~> 0.1.3'
  gem 'rb-fsevent', '~> 0.9.1', require: false if RUBY_PLATFORM =~ /darwin/i

  gem 'guard-rspec', '~> 1.2.1'
  gem 'guard-spork', '~> 1.1.0'

  gem 'spork-rails', '~> 3.2.0'

  # Pry: IRB + ruby debug alternative which is active and easier to install
  gem 'pry-remote', '~> 0.1.6' # Needed for using pry in spork
  gem 'pry-rails', '~> 0.2.1'
  gem 'pry-nav', '~> 0.2.2'
  gem 'pry-coolline', '~> 0.1.5'
end

group :development, :test do
  gem 'rspec-rails', '~> 2.11.0'
  gem 'guard', '~> 1.3.0'

  gem 'rb-inotify', '~> 0.8.8',  require: false
  gem 'rb-fsevent', '~> 0.9.1',  require: false
  gem 'rb-fchange', '~> 0.0.5',  require: false

  gem 'mailcatcher', '~> 0.5.8', require: false

  gem 'simplecov', '~> 0.6.4',   require: false
  gem 'delorean', '~> 2.0.0'
end

group :test do
  gem 'fabrication', '~> 2.2.2'
  gem 'database_cleaner', '~> 0.8.0'

  gem 'delorean', '~> 2.0.0'

  gem 'capybara', '~> 1.1.2'
  gem 'launchy', '~> 2.1.2'

  gem 'guard-rspec', '~> 1.2.1'
  gem 'fuubar', '~> 1.0.0'

  gem 'cucumber-rails', '~> 1.3.0', require: false
end

group :staging do
  gem 'mail_safe', '~> 0.3.1'
  gem 'delorean', '~> 2.0.0'
end
