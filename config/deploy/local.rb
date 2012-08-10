set :port, 4547
set :domain, '192.168.1.6'
set :rails_env, :staging
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true
