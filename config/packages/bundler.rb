package :bundler do
  description 'Bundler'
  gem "bundler"
  
  verify do
    has_gem 'bundler'
  end
end
