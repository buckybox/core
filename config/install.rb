#Monkey patch to allow capistrano vars to be fetch within sprinkle
module Sprinkle::Package
  class Package
    @@capistrano = {}
    @@db_config = {}
    @@stage = 'staging'

    def self.set_variables=(set)
      @@capistrano = set
    end

    def self.fetch(name)
      @@capistrano[name]
    end

    def self.exists?(name)
      @@capistrano.key?(name)
    end

    def self.add_db(stage, db)
      @@db_config = db[stage]
    end

    def self.database_name
      @@db_config["database"]
    end

    def self.stage=(s)
      @@stage = s
    end

    def self.stage
      @@stage
    end
    
    STAGES = ['production', 'staging']
    def self.preprocess_stage(text)
      STAGES.each do |s|
        next if stage == s #Remove all stages from config except this stage
        marker = s.upcase
        text = text.gsub(/##{marker}.*?##{marker}/m,'')
      end
      return text.gsub(/#\{RAILS_ENV\}/, stage)
    end

  end
end

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
  requires :nginx
  requires :setup_db
  requires :nodejs
  requires :postfix
  requires :monit
  requires :munin
  requires :munin_passenger
  requires :redis
  requires :logrotate
end

