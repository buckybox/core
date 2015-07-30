module Messaging
  class Distributor
    AUTO_MESSAGE_TAG = "[[auto-messages]]".freeze

    def initialize(distributor)
      @distributor = distributor
    end

    def tracking_after_create
      return unless track_env?

      messaging_proxy.create_user(tracking_data)
      messaging_proxy.add_tag(distributor.id, AUTO_MESSAGE_TAG)
    end

    def tracking_after_save
      return unless track_env?

      messaging_proxy.delay(delayed_job_options).update_user(
        distributor.id, tracking_data
      )
    end

    def track(action_name, occurred_at = Time.current)
      return unless track_env?

      messaging_proxy.delay(delayed_job_options).track(
        distributor.id, action_name, occurred_at
      )
    end

    def track_env?
      @track_env ||= Rails.env.production?
    end

  private

    attr_reader :distributor

    def messaging_proxy
      @messaging_proxy ||= Messaging::IntercomProxy.instance
    end

    def tracking_data
      {
        user_id:     distributor.id,
        email:       distributor.email,
        name:        distributor.contact_name,
        created_at:  distributor.created_at,
      }
    end

    def delayed_job_options
      @delayed_job_options ||= {
        priority: Figaro.env.delayed_job_priority_low,
        queue: "#{__FILE__}:#{__LINE__}",
      }.freeze
    end
  end
end
