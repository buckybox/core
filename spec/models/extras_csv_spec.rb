require 'spec_helper'

describe ExtrasCsv do
  describe "#generate" do
    before(:all) do
      @date = Date.current

      distributor = Fabricate(:distributor, advance_days: 1)

      extras = 4.times.map do |i|
        Fabricate(:extra,
          name: "Extra #{i}",
          distributor: distributor,
          price_cents: i*200+50,
          unit: ['kg','l','each','g'][i]
        )
      end

      customers = 2.times.map { |i| Fabricate(:customer, distributor: distributor) }

      box = Fabricate(:box, distributor: distributor, extras_limit: 10)

      orders = 2.times.map do |i|
        Fabricate(:order,
          account: customers[i].account,
          box: box,
          schedule_rule: new_everyday_schedule(Date.current)
        )
      end

      4.times.map do |i|
        Fabricate(:order_extra, order: orders[i%2], extra: extras[i%3], count: i+1)
      end

      distributor.packing_lists.destroy_all
      distributor.delivery_lists.destroy_all
      distributor.reload
      distributor.generate_required_daily_lists

      @rows = CSV.parse(ExtrasCsv.generate(distributor, @date))
    end

    it "exports the header into the csv" do
      @rows.first.should eq ["delivery date", "extra line item name", "extra line item unit", "extra line item unit price", "quantity"]
    end

    specify { @rows[1].should eq [@date.iso8601, "Extra 0", "kg",   "0.50", "5"] }
    specify { @rows[2].should eq [@date.iso8601, "Extra 1", "l",    "2.50", "2"] }
    specify { @rows[3].should eq [@date.iso8601, "Extra 2", "each", "4.50", "3"] }
    specify { @rows[4].should eq [@date.iso8601, "Extra 3", "g",    "6.50", "0"] }
  end
end

