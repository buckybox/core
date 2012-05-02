require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row, :focus do

  let(:distributor){ mock_model(Distributor)}

  context :single_match do
    before do
      distributor.stub(:customers).and_return([
        Fabricate.build(:customer, number: 67),
        Fabricate.build(:customer, number: 999),
        Fabricate.build(:customer, number: 1),
        @match = Fabricate.build(:customer, number: 45),
        Fabricate.build(:customer, number: 8734)
      ])
    end

    it "should match customer" do
      row = Row.new("12 Oct 2011", "BuckyBox #45 FROM J E SMITH ;Payment from J E SMITH #23", "5")
      row.customer_match(distributor).should eq([@match])
    end
  end

  context :multiple_match do
    before do
      distributor.stub(:customers).and_return([
        Fabricate.build(:customer, number: 67),
        @match1 = Fabricate.build(:customer, number: 999),
        Fabricate.build(:customer, number: 1),
        @match2 = Fabricate.build(:customer, number: 45),
        Fabricate.build(:customer, number: 8734)
      ])
    end

    it "should match customer" do
      row = Row.new("12 Oct 2011", "BuckyBox #45 FROM J E SMITH ;Payment from J E SMITH #999", "5")
      row.customer_match(distributor).should eq([@match2, @match1])
    end
  end  
end
