require 'singleton'

module Bucky
  class Usercycle
    include Singleton

    def initialize
      # Set up a client to talk to the Usercycle API
      @client = ::Usercycle::Client.new(
        Figaro.env.usercycle_api_key,
        Figaro.env.usercycle_api_url
      )
    end

    def event(identity, action_name, properties = {}, occurred_at = Time.now)
      raise TypeError, "Identity cannot be nil" if identity.nil?

      # FIXME: temporary plug to try out Vero
      identity.track(action_name, properties)

      if Rails.env.production? || Rails.env.staging?
        @client.event.delay(
          priority: Figaro.env.delayed_job_priority_low
        ).create(identity.id, action_name, properties, occurred_at)
      end
    end

    def track(identity)
      event identity, 'came_back'
    end
  end
end

