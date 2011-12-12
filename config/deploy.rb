set :application, "bucky_box"
set :user, application
set :repository,  "git@github.com:enspiral/#{application}.git"
set :scm, :git

set :deploy_via, :remote_cache
set :rake, "bundle exec rake"
set :use_sudo, false

task :staging do
  set :rails_env, :staging
end

task :production do
  set :rails_env, :production
end

set :domain, '173.255.206.188'
set :deploy_to, "/home/#{application}/#{rails_env}"
set :branch, rails_env

role :web, domain
role :app, domain
role :db,  domain, :primary => true

namespace :deploy do
  [:stop, :start, :restart].each do |task_name|
    task task_name, :roles => [:app] do
      run "cd #{current_path} && touch tmp/restart.txt"
    end
  end

  task :symlink_configs do
    run %( cd #{release_path} &&
      ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml
    )
  end
end

after "deploy:update_code" do
  deploy.symlink_configs
end

require './config/boot'
require 'capistrano_colors'
require 'bundler/capistrano'
require 'airbrake/capistrano'

