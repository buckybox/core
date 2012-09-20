package :scoutapp do
  description 'Install Scout Required Gems'
  gem "elif"
  gem "request-log-analyzer"
  
  verify do
    has_gem 'elif'
    has_gem 'request-log-analyzer'
  end
end
