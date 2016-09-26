require "spec_helper"

describe Distributor::Pricing do
  describe "#usage_between" do
    before do
      distributor = Fabricate(:distributor)

      @pricing = Distributor::Pricing.pricings_for_currency(distributor.currency).detect { |p| p.name == "Standard" }
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

  describe "#last_billed_date" do
    before do
      distributor = Fabricate(:distributor)

      @pricing = Distributor::Pricing.default_pricing_for_currency("USD")
      @pricing.distributor = distributor
      @pricing.save!
    end

    def assert_last_billed_date(today, expected)
      time_travel_to Date.parse(today)
      expect(@pricing.last_billed_date).to eq Date.parse(expected)
    end

    context "with invoicing_day_of_the_month = 10" do
      before do
        @pricing.invoicing_day_of_the_month = 10
        expect(@pricing).to be_valid
      end

      specify { assert_last_billed_date "2016-03-31", "2016-03-09" }
      specify { assert_last_billed_date "2016-03-12", "2016-03-09" }
      specify { assert_last_billed_date "2016-03-11", "2016-03-09" }
      specify { assert_last_billed_date "2016-03-10", "2016-02-09" }
      specify { assert_last_billed_date "2016-03-09", "2016-02-09" }
      specify { assert_last_billed_date "2016-03-02", "2016-02-09" }
      specify { assert_last_billed_date "2016-03-01", "2016-02-09" }
    end

    context "with invoicing_day_of_the_month = 1" do
      before do
        @pricing.invoicing_day_of_the_month = 1
        expect(@pricing).to be_valid
      end

      specify { assert_last_billed_date "2016-03-31", "2016-02-29" }
      specify { assert_last_billed_date "2016-03-10", "2016-02-29" }
      specify { assert_last_billed_date "2016-03-02", "2016-02-29" }
      specify { assert_last_billed_date "2016-03-01", "2016-01-31" }
      specify { assert_last_billed_date "2016-02-29", "2016-01-31" }
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
