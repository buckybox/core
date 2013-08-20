require 'spec_helper'

describe CustomerAccountHistoryCsv do
  describe "#generate" do
    
    it "exports customer data into csv" do
      @date = Date.current - 6.weeks
      @distributor = Fabricate(:distributor)

      @accounts = 2.times.collect do |i|
        c = Fabricate(:customer, distributor: @distributor, number: i+1, first_name: "C#{i+1}", last_name: "CL#{i+1}", email: "#{i+1}@buckybox.com")
        c.account
      end

      @accounts[0].subtract_from_balance(20, display_time: @date); @accounts[0].save!
      @accounts[0].add_to_balance(40, display_time: @date + 1.day); @accounts[0].save!
      @accounts[0].subtract_from_balance(60, display_time: @date + 2.day); @accounts[0].save!

      @accounts[1].add_to_balance(20, display_time: @date); @accounts[1].save!
      @accounts[1].subtract_from_balance(40, display_time: @date + 1.day); @accounts[1].save!
      @accounts[1].add_to_balance(60, display_time: @date + 2.day); @accounts[1].save!

      date = @date
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(date, @distributor))
      rows[1..-1].should eq [[date.iso8601, "0001", "C1", "CL1", "1@buckybox.com", "-20.0"],
                              [date.iso8601, "0002", "C2", "CL2", "2@buckybox.com", "20.0"]]

      date = date + 1.day
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(date, @distributor))
      rows[1..-1].should eq [[date.iso8601, "0001", "C1", "CL1", "1@buckybox.com", "20.0"],
                              [date.iso8601, "0002", "C2", "CL2", "2@buckybox.com", "-20.0"]]

      date = date + 1.day
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(date, @distributor))
      rows[1..-1].should eq [[date.iso8601, "0001", "C1", "CL1", "1@buckybox.com", "-40.0"],
                              [date.iso8601, "0002", "C2", "CL2", "2@buckybox.com", "40.0"]]
    end
  end
end
