class Webstore::SessionPersistance < ActiveRecord::Base
  serialize :collected_data, JSON

  def self.save(webstore_session)
    create(collected_data: webstore_session)
  end

  def webstore_session(session_class = Webstore::Session)
    attr_hash = collected_data.with_indifferent_access
    session_class.new(attr_hash)
  end
end
