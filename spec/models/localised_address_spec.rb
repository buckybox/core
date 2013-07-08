require 'spec_helper'

describe LocalisedAddress do
  describe "#postal_address" do
    def address(country)
      LocalisedAddress.new(
        street: "Cuba Street",
        city:   "Wellington",
        zip:    "6011",
        addressable: Fabricate(:distributor, name: "Foodie", country: country)
      )
    end

    it "returns the localised postal address" do
      nz = Fabricate(:country, alpha2: "NZ")
      de = Fabricate(:country, alpha2: "DE")

      address(nz).postal_address.should eq \
        "Foodie\nCuba Street\nWellington 6011\nNew Zealand"

      address(de).postal_address.should eq \
        "Foodie\nCuba Street\n6011 Wellington\nGermany"
    end
  end
end

