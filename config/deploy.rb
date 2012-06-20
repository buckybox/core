require './config/boot'
require 'capistrano_colors'
require 'bundler/capistrano'
require 'whenever/capistrano'
require 'airbrake/capistrano'
require 'tinder'

# HAX for Tinder until this is fixed: https://github.com/capistrano/capistrano/issues/168#issuecomment-4144687
Capistrano::Configuration::Namespaces::Namespace.class_eval do
  def capture(*args)
    parent.capture *args
  end
end

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

  task :campfire do
    config = YAML.load_file("config/campfire.yml")
    campfire = Tinder::Campfire.new config['account'], token: config['token'], ssl: config['ssl']
    ROOM = campfire.find_room_by_name config['room']
    ANOUNCE_USER = ENV['CAMPFIRE_NAME'] || `whoami`.strip
  end

  task :pre_announce do
    ROOM.speak "#{ANOUNCE_USER} is preparing to deploy #{application} to #{stage}"
  end

  task :post_announce do
    ROOM.speak "#{ANOUNCE_USER} finished deploying #{application} to #{stage}"
    ROOM.speak "http://media.giantbomb.com/uploads/5/58937/2135457-success_baby_kid.jpg" #Change when MemeGen back up
  end
end

after 'deploy:assets:symlink' do
  deploy.symlink_configs
end

before "deploy", "deploy:campfire", "deploy:pre_announce"
after "deploy:restart", "deploy:cleanup", "deploy:post_announce"

