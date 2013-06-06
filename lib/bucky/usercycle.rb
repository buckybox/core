require 'singleton'
require 'usercycle'

module Bucky
  class Usercycle
    include Singleton

    def initialize
      # set up a client to talk to the USERcycle API
      @client = ::Usercycle::Client.new(
        Figaro.env.usercycle_api_key,
        Figaro.env.usercycle_api_url
      )
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

