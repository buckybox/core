require 'singleton'
require 'usercycle'

module Bucky
  class Usercycle
    include Singleton

    API_KEY = '624a19c076449cb71c750ab7ef5909de7f488dc1'
    API_URL = 'https://api.usercycle.com/api/v1'

    def initialize
      # set up a client to talk to the USERcycle API
      @client = ::Usercycle::Client.new API_KEY, API_URL
    end

    def event(identity, action_name, *args)
      raise "Identity cannot be nil" if identity.nil?

      if Rails.env.production? || Rails.env.staging?
        @client.event.create(identity.id, action_name, *args)
      else
        warn "Usercycle event '#{action_name}' not tracked for the current environment"
      end
    end

    def track(identity)
      event identity, 'came_back'
    end
  end
end

