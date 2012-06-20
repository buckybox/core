require './config/boot'
require 'capistrano_colors'
require 'bundler/capistrano'
require 'whenever/capistrano'
require 'airbrake/capistrano'
require 'capistrano/campfire'

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

set :campfire_options, :account => 'enspiral',
                       :room => 'Bucky Box',
                       :token => 'e70855b772add9a9daa5c74c948c3f98ef31dc96',
                       :ssl => true

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

  task :campfire_before do
    someone = ENV['CAMPFIRE_NAME'] || `whoami`.strip
    campfire_room.speak "#{someone} started deploying #{application} #{branch} to #{stage}"
  end

  task :campfire_after do
    someone = ENV['CAMPFIRE_NAME'] || `whoami`.strip
    campfire_room.speak "#{someone} finished deploying #{application} #{branch} to #{stage}"
  end
end

after 'deploy:assets:symlink' do
  deploy.symlink_configs
end

before "deploy", "deploy:campfire_before"
after "deploy:restart", "deploy:campfire_after"

after "deploy:restart", "deploy:cleanup" # Delete old project folders

