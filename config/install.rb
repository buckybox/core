stage = ARGV.first || 'local'

# Load DB config
db_config = YAML::load(IO.read(File.expand_path("../deploy/database.yml", __FILE__)))
Sprinkle::Package::Package.add_db(stage, db_config)
Sprinkle::Package::Package.stage = stage

deployment do
  delivery :capistrano do
    recipes 'Capfile'
    recipes 'config/deploy/sprinkle.rb'
    recipes "config/deploy/#{stage}.rb"
  end
  source do
    prefix '/usr/local'
    archives '/usr/local/sources'
    builds '/usr/local/build'
  end
end

require File.expand_path('../helper', __FILE__)

policy :myapp, :roles => :app do
  requires :build_essential
  requires :htop
  requires :git
  requires :ruby
  requires :ruby_tuned
  requires :imagemagick
  requires :bundler
  requires :rubygems
  requires :passenger
  requires :postgres_and_gem
  requires :certs
  requires :nginx
  requires :setup_db
  requires :nodejs
  requires :postfix
  requires :monit
  requires :munin
  requires :munin_passenger
  requires :logrotate
  requires :redis
end

