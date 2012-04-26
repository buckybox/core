source 'http://rubygems.org'

# Core
gem 'rails', '~> 3.2.1'

# Database
gem 'pg'

group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'zurb-foundation'
end

gem 'haml-rails'
gem 'sass-rails'
gem 'jquery-rails'

gem 'devise', '~> 1.5.3'
gem 'multi_json', '~> 1.0.4'
gem 'simple_form', '~> 1.5.2'
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
gem 'ice_cube'
gem 'whenever'
gem 'newrelic_rpm'
gem 'acts_as_list'
gem 'default_value_for'

group :development do
  gem 'nifty-generators', require: false

  gem 'capistrano'
  gem 'capistrano_colors'

  # ruby-debug needs extra stuff to work on 1.9.3, see here -> https://gist.github.com/1885892
  # consider using Pry instead https://github.com/pry/pry
  gem 'linecache19', '0.5.13'
  gem 'ruby-debug-base19', '0.11.26'
  gem 'ruby-debug19', require: 'ruby-debug'
  gem 'hirb'
  gem 'wirble'
  gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
  gem 'guard-rspec'
  gem 'guard-spork'
  #gem 'growl_notify'
  gem 'spork-rails'
  gem 'pry-remote'
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
  gem 'fabrication'
  gem 'database_cleaner'

  gem 'delorean'

  gem 'capybara'
  gem 'launchy'

  gem 'guard-rspec'
  gem 'fuubar'
end

group :staging do
  gem 'mail_safe'
  gem 'delorean'
end
