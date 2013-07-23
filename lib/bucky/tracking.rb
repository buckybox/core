require 'singleton'

module Bucky
  class Tracking
    include Singleton

    def event(identity, action_name, properties = {}, occurred_at = Time.now)
      raise TypeError, "Identity cannot be nil" if identity.nil?

      if Rails.env.production? || Rails.env.staging?
        # Vero tracking
        identity.delay(
          priority: Figaro.env.delayed_job_priority_low
        ).track(action_name, properties)
      end
    end

    def track(identity)
      event identity, 'came_back'
    end
  end
end

