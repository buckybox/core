require "timeout"

module Bucky
  module Geolocation
    FREE_GEO_IP_URL = "http://freegeoip.net/json/"

  module_function

    def get_country ip_address
      info = Geolocation.get_geoip_info ip_address
      info["country_code"] if info
    end

    def get_time_zone country_code
      country = Country.where(alpha2: country_code).first
      country.default_time_zone if country
    end

    # FIXME: this is terribly filthy
    def get_address_form country_code, resource
      model_name = resource.class.model_name.downcase
      format = Biggs::Format.new(country_code).format_string

      unless format
        # fallback to NZ format if not available for this country
        format = Biggs::Format.new("NZ").format_string
      end

      required_fields = %w(street city)

      field_descriptions = {
        "street" => "Street and Number",
        "city"   => "City",
        "zip"    => "Post code / Zip",
        "state"  => "Region / Province / State"
      }

      format.split("\n").map do |line|
        fields = line.scan(/{{(.+?)}}/).flatten - ["recipient", "country"]
        width = 100.0 / fields.size

        html = fields.map do |field|
          value = resource.localised_address.public_send(field)
          %Q{
            <input id="#{model_name}_localised_address_#{field}" name="#{model_name}[localised_address_attributes][#{field}]" placeholder="#{field_descriptions[field]}" #{'required="required"' if field.in? required_fields} type="text" style="width: #{width}%" value="#{value}">
          }.strip
        end.join

        "<div>#{html}</div>" if html.present?
      end.join.html_safe
    end

    def get_geoip_info ip_address
      uri = URI.parse([FREE_GEO_IP_URL, ip_address].join)
      http = Net::HTTP.new(uri.host, uri.port)

      begin
        Timeout::timeout(1) do
          response = http.request(Net::HTTP::Get.new(uri.request_uri))
          JSON.parse(response.body)
        end
      rescue Timeout::Error, SocketError, JSON::ParserError
        # too slow or not valid JSON, just return nil
      end
    end
  end
end

