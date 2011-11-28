source 'http://rubygems.org'

# Core
gem 'rails', '3.1.3'

# Database
gem 'pg'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.5'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :development, :test do
  gem 'rspec-rails'
  
  gem 'ruby-debug19', :require => false
  gem 'mailcatcher', :require => false
end

group :test do
  gem 'fabrication'
  gem 'capybara'
  gem 'launchy'
end

group :staging do
  gem 'mail_safe'
end
