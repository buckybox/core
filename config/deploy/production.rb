set :domain, '173.255.206.188'
set :rails_env, :production
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true
