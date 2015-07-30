require "singleton"

module Messaging
  class IntercomProxy
    include Singleton

    NON_FATAL_EXCEPTIONS = [
      ::Intercom::ServerError,
      ::Intercom::BadGatewayError,
      ::Intercom::ServiceUnavailableError,
      Errno::ECONNRESET,
    ].freeze

    def update_user(id, attrs)
      user = find_user(id)
      return if user.blank?

      attrs.each { |key, value| user.send("#{key}=", value) }
      user.save

    rescue *NON_FATAL_EXCEPTIONS => e
      Bugsnag.notify(e)
    end

    def create_user(attrs)
      Retryable.retryable(retryable_options) do
        ::Intercom::User.create(attrs)
      end
    end

    def add_tag(user_id, tag)
      add_user_to_tag(user_id, tag)
    end

    def remove_tag(user_id, tag)
      remove_user_from_tag(user_id, tag)
    end

    def update_tags(attrs)
      attrs[:tag_list].each do |name|
        add_user_to_tag(attrs[:id], name)
      end
    end

    def track(id, action_name, occurred_at = Time.current)
      Retryable.retryable(retryable_options) do
        user = ::Intercom::User.find(user_id: id)
        user.custom_attributes["#{action_name}_at"] = occurred_at
        user.save
      end

    rescue *NON_FATAL_EXCEPTIONS => e
      Bugsnag.notify(e)
    end

  private

    def find_user(user_id)
      Retryable.retryable(retryable_options) do
        ::Intercom::User.find(user_id: user_id)
      end
    rescue Intercom::ResourceNotFound
      nil
    end

    def add_user_to_tag(user_id, name)
      intercom_user = find_user(user_id)
      ::Intercom::Tag.tag_users(name, [intercom_user.id])
    end

    def remove_user_from_tag(user_id, name)
      intercom_user = find_user(user_id)
      ::Intercom::Tag.untag_users(name, [intercom_user.id])
    end

    def retryable_options
      {
        tries: 3,
        sleep: 0,
        on: NON_FATAL_EXCEPTIONS
      }.freeze
    end
  end
end
