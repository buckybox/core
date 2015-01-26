require 'spec_helper'

describe Country do
  context "NZ" do
    before do
      Fabricate(:country, alpha2: "NZ")
      @country = Country.find_by_alpha2 "NZ"
    end

    describe "#name" do
      it "returns New Zealand" do
        expect(@country.name).to eq "New Zealand"
      end
    end

    describe "#full_name" do
      it "aliases #name" do
        expect(@country.full_name).to eq @country.name
      end
    end

    describe "#currency" do
      it "returns NZD" do
        expect(@country.currency).to eq "NZD"
      end
    end

    describe "#time_zone" do
      it "returns Pacific/Auckland" do
        expect(@country.time_zone).to eq "Pacific/Auckland"
      end
    end
  end
end

