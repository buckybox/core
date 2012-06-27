set :port, 17766
set :domain, '198.101.213.84' #rackspace's internal ip FYI 10.179.166.196
set :rails_env, :production
set :stage, rails_env
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true
