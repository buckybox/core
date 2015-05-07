set :port, 30_245
set :domain, '108.166.89.29' # rackspace's internal ip FYI 10.179.166.196
set :rails_env, :production
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, "master"

role :web, domain
role :app, domain
role :db,  domain, :primary => true
