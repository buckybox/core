require 'spec_helper.rb'

describe Distributor::ReportsController do
  as_distributor

  describe "#export_customer_account_history" do
    let(:date) { Date.today }

    before do
      @post = lambda { post :export_customer_account_history, export: {date: date.iso8601}}
    end

    it "downloads a csv" do
      CustomerAccountHistoryCsv.stub(:generate).and_return("")
      @post.call
      response.headers['Content-Type'].should eq "text/csv; charset=utf-8; header=present"
    end

    it "exports customer data into csv" do
      CustomerAccountHistoryCsv.stub(:generate).and_return("I am the king of csvs")
      @post.call
      response.body.should eq "I am the king of csvs"
    end

    it "calls CustomerAccountHistoryCsv.generate" do
      CustomerAccountHistoryCsv.stub(:generate)
      CustomerAccountHistoryCsv.should_receive(:generate).with(date, @distributor)
      @post.call
    end
  end
end
