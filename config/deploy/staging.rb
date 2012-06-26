set :port, 3887
set :domain, '108.171.183.164'
set :rails_env, :staging
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true
