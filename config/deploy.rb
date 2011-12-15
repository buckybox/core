set :application, "bucky_box"
set :user, application
set :repository,  "git@github.com:enspiral/#{application}.git"

set :scm, :git
set :use_sudo, false
set :rake, 'bundle exec rake'

task :staging do
  set :rails_env, :staging
  set :deploy_to, "/home/#{application}/staging"
  set :branch, 'staging'
end

task :production do
  set :rails_env, :production
  set :deploy_to, "/home/#{application}/production"
  set :branch, 'production'
end

set :domain, '173.255.206.188'

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

after 'deploy:assets:symlink' do
  deploy.symlink_configs
end

require './config/boot'
require 'capistrano_colors'
require 'bundler/capistrano'
require 'airbrake/capistrano'

