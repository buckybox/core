module Webstore
  class Session
    def self.serialize(args = {})
      order_id = args[:order_id].to_i
      { order_id: order_id }
    end
  end
end
