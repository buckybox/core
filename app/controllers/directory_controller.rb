require "geokit"

class DirectoryController < ApplicationController
  layout false

  caches_action :index, expires_in: 24.hours

  def index
    distributors = Distributor.active.select(&:active_webstore)

    list = distributors.map.each_with_index do |distributor, index|
      address = distributor.localised_address
      next unless address

      full_address = [address.street, address.city, address.zip, address.country].join(" ")

      # NOTE: Google allows up to 10 requests per second
      # https://developers.google.com/maps/documentation/geocoding/?csw=1#Limits
      sleep 2 if index % 9 == 0

      retryable(tries: 3, sleep: 1, on: Geokit::Geocoders::TooManyQueriesError) do
        geocoded_address = Geokit::Geocoders::GoogleGeocoder.geocode full_address
      end

      OpenStruct.new(
        name: distributor.name,
        address: full_address,
        ll: geocoded_address.ll.split(","),
        webstore: "https://my.buckybox.com/webstore/#{distributor.parameter_name}",
      ).freeze
    end.compact

    render locals: { list: list }
  end
end
