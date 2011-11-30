source 'http://rubygems.org'

# Core
gem 'rails', '3.1.3'

# Database
gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'zurb-foundation'
end

gem 'jquery-rails'
gem 'haml-rails'
gem 'devise'
gem 'simple_form'
gem 'inherited_resources'

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
  gem 'capybara'
  gem 'launchy'
  gem 'guard-rspec'
end

group :staging do
  gem 'mail_safe'
end
