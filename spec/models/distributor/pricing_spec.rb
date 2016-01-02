require "spec_helper"

describe Distributor::Pricing do
  describe "#description" do
    before do
      @pricing = Distributor::Pricing.new(
        name: "Test",
        discount_percentage: 10,
      )

      @pricing.distributor = mock_model("Distributor", currency: "NZD")
    end

    specify do
      @pricing.percentage_fee = 2
      @pricing.percentage_fee_max = 0.5

      expect(@pricing.description).to eq "2.0% capped at $0.50 NZD per delivery"
    end

    specify do
      @pricing.percentage_fee = 3.5
      @pricing.percentage_fee_max = 0.5
      @pricing.flat_fee = 80

      expect(@pricing.description).to eq "3.5% capped at $0.50 NZD per delivery + $80.00 NZD monthly"
    end

    specify do
      @pricing.percentage_fee = 0
      @pricing.flat_fee = 100

      expect(@pricing.description).to eq "$100.00 NZD monthly"
    end
  end
end
