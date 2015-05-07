require 'spec_helper'

describe LocalisedAddress do
  describe "#postal_address" do
    def address(country)
      address = LocalisedAddress.new(
        street: "Cuba Street",
        city:   "Wellington",
        zip:    "6011",
      )

      addressable = double("addressable",
        name: "Foodie",
        country: country,
      )

      allow(address).to receive(:addressable) { addressable }

      address
    end

    it "returns the localised postal address" do
      nz = Fabricate(:country, alpha2: "NZ")
      de = Fabricate(:country, alpha2: "DE")

      expect(address(nz).postal_address).to eq \
        "Foodie\nCuba Street\nWellington 6011\nNew Zealand"

      expect(address(de).postal_address).to eq \
        "Foodie\nCuba Street\n6011 Wellington\nGermany"
    end
  end
end
