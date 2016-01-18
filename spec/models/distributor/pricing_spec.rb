require "spec_helper"

describe Distributor::Pricing do
  describe "#usage_between" do
    before do
      distributor = Fabricate(:distributor)

      @pricing = Distributor::Pricing.default_pricing_for_currency(distributor.currency)
      @pricing.distributor = distributor
      @pricing.save!
    end

    it "compute correct usage amount" do
      [40, 60, 80].each do |amount|
        Fabricate(:deduction,
          distributor: @pricing.distributor,
          created_at: 1.week.ago,
          deductable_type: "Delivery",
          amount: amount,
        )
      end

      usage = @pricing.usage_between(1.month.ago.to_date, Date.current)
      expected = 100 + 0.2 + 0.3 + 0.3

      expect(usage).to eq expected
    end

    context "with a discount" do
      let(:discount_percentage) { 20 }

      before do
        @pricing.discount_percentage = discount_percentage
      end

      it "applies the discount" do
        Fabricate(:deduction,
          distributor: @pricing.distributor,
          created_at: 1.week.ago,
          deductable_type: "Delivery",
          amount: 20,
        )

        usage = @pricing.usage_between(1.month.ago.to_date, Date.current)
        expected = (100 + 0.1) * ((100.0 - discount_percentage) / 100)

        expect(usage).to eq expected
      end
    end
  end

  describe "#description" do
    before do
      @pricing = Distributor::Pricing.new(
        name: "Test",
        discount_percentage: 10,
        currency: "NZD",
      )

      @pricing.distributor = mock_model("Distributor")
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
