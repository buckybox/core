require 'spec_helper'

describe CustomerAccountHistoryCsv do
  describe "#generate" do
    
    before(:all) do
      @date = 1.week.ago.to_date
      @distributor = Fabricate(:distributor)

      @customers = 2.times.collect do |i|
        customer = Fabricate(:customer, distributor: @distributor, number: i+1, first_name: "C#{i+1}", last_name: "CL#{i+1}", email: "#{i+1}@buckybox.com")
        6.times do |j|
          l = j+i
          date = 6.weeks.ago + j.weeks
          account = customer.account
          account.subtract_from_balance(l*40, display_time: date)
          account.add_to_balance(l*45, display_time: date)
          account.save!
        end
        customer.reload
      end
    end

    it "exports the header into the csv" do
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(@date, @distributor))
      rows.first.should eq ["date", "customer number", "customer first name", "customer last name", "customer email", "customer account balance"]
    end

    it "exports customer data into csv" do
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(@date, @distributor))
      rows[1..-1].should eq [[@date.iso8601, "0001", "C1", "CL1", "1@buckybox.com", "50.0"],
                              [@date.iso8601, "0002", "C2", "CL2", "2@buckybox.com", "75.0"]]
    end
    
    it "exports customer data into csv" do
      date = @date - 3.weeks
      rows = CSV.parse(CustomerAccountHistoryCsv.generate(date, @distributor))
      rows[1..-1].should eq [[date.iso8601, "0001", "C1", "CL1", "1@buckybox.com", "5.0"],
                              [date.iso8601, "0002", "C2", "CL2", "2@buckybox.com", "15.0"]]
    end
  end
end
