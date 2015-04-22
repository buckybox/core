class Distributor::Map::Directory

  def self.generate
    directory = new
    directory.generate
  end

  def generate
    distributor_and_addresses.map do |distributor|
      address = distributor.localised_address

      geocoded_address = nil

      address_in_sections(address).each do |address_parts|
        full_address = address_parts.join(" ").squeeze(" ")
        geocoded_address = geocode_address(full_address)

        if geocoded_address.success
          break
        else
          geocoded_address = nil
        end
      end

      raise "Cannot geocode address" unless geocoded_address

      full_address = [address.street, address.city, address.zip, address.country].join(" ").squeeze(" ")

      args = {
        name:     distributor.name,
        address:  full_address,
        ll:       geocoded_address.ll.split(","),
        webstore: distributor.webstore_url,
      }
      Distributor::Map::Pin.new(args)
    end.compact
  end

private

  def geocode_address(address)
    # NOTE: Google allows up to 10 requests per second
    # https://developers.google.com/maps/documentation/geocoding/?csw=1#Limits
    Retryable.retryable(tries: 3, sleep: 2, on: Geokit::Geocoders::TooManyQueriesError) do
      Geokit::Geocoders::GoogleGeocoder.geocode address
    end
  end

  def distributor_and_addresses
    Distributor.active_webstore.joins(:localised_address).active
  end

  def address_in_sections(address)
    [

      [address.street, address.city, address.zip, address.state, address.country],
      [address.city, address.zip, address.country],
      [address.country],

    ]
  end

end
