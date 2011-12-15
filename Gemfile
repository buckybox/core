source 'http://rubygems.org'

# Core
gem 'rails', '3.1.3'

# Database
gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'zurb-foundation'
end

gem 'haml-rails'
gem 'sass-rails'
gem 'jquery-rails'

gem 'devise'
gem 'simple_form'
gem 'inherited_resources'
gem 'mini_magick'
gem 'carrierwave'
gem 'money'
gem 'acts-as-taggable-on'
gem 'pg_search'
gem 'kaminari'
gem 'airbrake'
gem 'analytical'
gem 'postmark-rails'

group :development do
  gem 'nifty-generators', :require => false

  gem 'capistrano'
  gem 'capistrano_colors'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'guard'

  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  
  gem 'ruby-debug19', :require => false
  gem 'mailcatcher', :require => false
end

group :test do
  gem 'fabrication'
  gem 'database_cleaner'

  gem 'capybara'
  gem 'launchy'
  
  gem 'guard-rspec'
  gem 'fuubar'
end

group :staging do
  gem 'mail_safe'
end
