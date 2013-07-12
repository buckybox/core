module Bucky
  module Email
    # @return Sanitised header usable with Mandrill
    def sanitise_email_header header
      header.gsub ":", ""
    end
  end
end
