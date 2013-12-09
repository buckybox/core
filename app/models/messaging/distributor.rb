module Messaging
  class Distributor

    AUTO_MESSAGE_TAG = "[[auto-messages]]"
    WEBSTORE_ENABLED_TAG = "[webstore]-on"
    WEBSTORE_DISABLED_TAG = "[webstore]-off"

    def initialize(distributor)
      @distributor = distributor
    end

    def tracking_after_create
      messaging_proxy.create_user(tracking_data, Rails.env)
      messaging_proxy.add_tag(distributor.id, AUTO_MESSAGE_TAG, Rails.env)
    end

    def tracking_after_save
      update
      toggle_webstore_tag if distributor.webstore_status_changed?
    end

    def toggle_webstore_tag
      delay(
        priority: Figaro.env.delayed_job_priority_low,
        queue: "#{__FILE__}:#{__LINE__}",
      ).delayed_toggle_webstore_tag
    end

    def update
      delay(
        priority: Figaro.env.delayed_job_priority_low,
        queue: "#{__FILE__}:#{__LINE__}",
      ).delayed_update
    end

    def delayed_update
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
          phone:         distributor.phone,
          needs_setup:   distributor.needs_setup?,
          admin_link:    Rails.application.routes.url_helpers.admin_distributor_url(
            id: distributor.id,
            host: Figaro.env.host,
          )
        }
      }
    end

    def update_tags
      messaging_proxy.update_tags({id: distributor.id, tag_list: distributor.tag_list}, Rails.env)
    end

    def delayed_toggle_webstore_tag
      if distributor.active_webstore?
        messaging_proxy.add_tag(distributor.id, WEBSTORE_ENABLED_TAG, Rails.env)
        messaging_proxy.remove_tag(distributor.id, WEBSTORE_DISABLED_TAG, Rails.env)
      else
        messaging_proxy.add_tag(distributor.id, WEBSTORE_DISABLED_TAG, Rails.env)
        messaging_proxy.remove_tag(distributor.id, WEBSTORE_ENABLED_TAG, Rails.env)
      end
    end

    def messaging_proxy
      Messaging::IntercomProxy.instance
    end
  end
end
