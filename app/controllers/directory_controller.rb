require "geokit"

class DirectoryController < ApplicationController
  layout false

  caches_action :index, expires_in: 24.hours

  def index
    distributors = Distributor.active.select(&:active_webstore)

    list = distributors.map do |distributor|
      address = distributor.localised_address
      next unless address

      full_address = [address.street, address.city, address.zip, address.country].join(" ")

      geocoded_address = Geokit::Geocoders::GoogleGeocoder.geocode full_address

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
