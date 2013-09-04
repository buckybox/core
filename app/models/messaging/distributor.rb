module Messaging
  class Distributor
    def initialize(distributor)
      @distributor = distributor
    end

    def tracking_after_create
      messaging_proxy.create_user(tracking_data, Rails.env)
    end

    def tracking_after_save
      delay(
        priority: Figaro.env.delayed_job_priority_low
      ).update_tags
    end

    def update
      messaging_proxy.update_user(distributor.id, tracking_data, Rails.env)
    end

    def track(action_name, occurred_at = Time.current, env = Rails.env)
      messaging_proxy.track(distributor.id, action_name, occurred_at, env)
    end

    def skip?(env = Rails.env)
      messaging_proxy.skip?(env)
    end

  private

    attr_reader :distributor

    def tracking_data
      {
        user_id:     distributor.id,
        email:       distributor.email,
        name:        distributor.contact_name,
        created_at:  distributor.created_at,
        custom_data: {
          business_name: distributor.name,
          phone:        distributor.phone,
        }
      }
    end

    def update_tags
      messaging_proxy.update_tags({id: distributor.id, tag_list: distributor.tag_list}, Rails.env)
    end

    def messaging_proxy
      Messaging::IntercomProxy.instance
    end
  end
end
