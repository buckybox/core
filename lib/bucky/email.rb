module Bucky
  module Email
    # @return Sanitized header usable with Mandrill
    # @see http://www.ietf.org/rfc/rfc2047.txt - The "Q" encoding
    def sanitize_email_header(header)
      sanitized_header = header.dup

      %w(: ,).each do |char|
        hex = char.ord.to_s(16).upcase
        sanitized_header.gsub! char, "=?UTF-8?Q?=#{hex}?="
      end

      sanitized_header
    end
  end
end
