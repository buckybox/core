require "timeout"

module Bucky
  module Geolocation
    FREE_GEO_IP_URL = "http://freegeoip.net/json/"

  module_function

    def get_country ip_address
      info = Geolocation.get_geoip_info ip_address
      info["country_name"] if info
    end

    def get_time_zone country_name
      country = Country.where(full_name: country_name).first
      country.default_time_zone if country
    end

    def get_geoip_info ip_address
      uri = URI.parse([FREE_GEO_IP_URL, ip_address].join)
      http = Net::HTTP.new(uri.host, uri.port)

      begin
        Timeout::timeout(1) do
          response = http.request(Net::HTTP::Get.new(uri.request_uri))
          JSON.parse(response.body)
        end
      rescue Timeout::Error
        # too slow, just return nil
      end
    end
  end
end

