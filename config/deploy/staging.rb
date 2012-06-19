set :port, 27879
set :domain, '50.56.218.56'
set :rails_env, :staging
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true
