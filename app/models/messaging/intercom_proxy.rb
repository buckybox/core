module Messaging
  class IntercomProxy
    NON_FATAL_EXCEPTIONS = [
      ::Intercom::ServerError,
      ::Intercom::BadGatewayError,
      ::Intercom::ServiceUnavailableError,
      Errno::ECONNRESET,
    ].freeze

    def self.instance
      @instance ||= Messaging::IntercomProxy.new
    end

    def update_user(id, attrs, env = nil)
      return if skip? env

      user = find_user(id)
      return if user.blank?

      attrs.each { |key, value| user.send("#{key}=", value) }
      user.save

    rescue *NON_FATAL_EXCEPTIONS => e
      Bugsnag.notify(e)
    end

    def create_user(attrs, env = nil)
      return if skip? env

      Retryable.retryable(retryable_options) do
        ::Intercom::User.create(attrs)
      end
    end

    def add_tag(user_id, tag, env = nil)
      return if skip? env

      add_user_to_tag(user_id, tag)
    end

    def remove_tag(user_id, tag, env = nil)
      return if skip? env

      remove_user_from_tag(user_id, tag)
    end

    def update_tags(attrs, env = nil)
      return if skip? env

      attrs[:tag_list].each do |name|
        add_user_to_tag(attrs[:id], name)
      end
    end

    def track(id, action_name, occurred_at = Time.current, env = nil)
      return if skip? env

      Retryable.retryable(retryable_options) do
        user = ::Intercom::User.find(user_id: id)
        user.custom_attributes["#{action_name}_at"] = occurred_at
        user.save
      end

    rescue *NON_FATAL_EXCEPTIONS => e
      Bugsnag.notify(e)
    end

    def skip?(env, expected_env = 'production')
      env != expected_env
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
        on: NON_FATAL_EXCEPTIONS,
      }.freeze
    end
  end
end
