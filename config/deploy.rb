set :application, 'bucky_box'
set :user, application
set :repository,  "git@github.com:enspiral/#{application}.git"
set :keep_releases, 4

set :scm, :git
set :use_sudo, false

set :rake, 'bundle exec rake'
set :whenever_command, 'bundle exec whenever'
set :ssh_options, { :forward_agent => true }

task :staging do
  set :domain, '173.255.206.188'
  set :rails_env, :staging
  set :stage, rails_env
  set :deploy_to, "/home/#{application}/#{rails_env}"
  set :branch, rails_env
  
  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true
end

task :production do
  set :domain, '173.255.206.188'
  set :rails_env, :production
  set :stage, rails_env
  set :deploy_to, "/home/#{application}/#{rails_env}"
  set :branch, rails_env
  
  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true
end

set :whenever_environment, defer { stage }
set :whenever_identifier, defer { "#{application}_#{stage}" }

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
after "deploy:restart", "deploy:cleanup" # Delete old project folders

require './config/boot'
require 'capistrano_colors'
require 'bundler/capistrano'
require 'whenever/capistrano'
require 'airbrake/capistrano'

