require "geokit"

class DirectoryController < ApplicationController
  layout false

  caches_action :index, expires_in: 24.hours

  def index
    distributors = Distributor.active.select(&:active_webstore)

    list = distributors.map do |distributor|
      address = distributor.localised_address
      next unless address

      geocoded_address = nil

      [

        [address.street, address.city, address.zip, address.state, address.country],
        [address.city, address.zip, address.country],
        [address.country],

      ].each do |address_parts|
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

      OpenStruct.new(
        name: distributor.name,
        address: full_address,
        ll: geocoded_address.ll.split(","),
        webstore: "https://my.buckybox.com/webstore/#{distributor.parameter_name}",
      ).freeze
    end.compact

    render locals: { list: list }
  end

private

  def geocode_address(address)
    # NOTE: Google allows up to 10 requests per second
    # https://developers.google.com/maps/documentation/geocoding/?csw=1#Limits
    retryable(tries: 3, sleep: 2, on: Geokit::Geocoders::TooManyQueriesError) do
      Geokit::Geocoders::GoogleGeocoder.geocode address
    end
  end
end
