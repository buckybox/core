require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row do

  let(:distributor){ mock_model(Distributor)}

  context :single_match do
    before do
      distributor.stub(:customers).and_return([
        mock_customer("0067", 0),
        mock_customer("0999", 0),
        mock_customer("0001", 0),
        @match = mock_customer("0045", 0),
        mock_customer("8734", 0)
      ])
    end

    it "should match customer" do
      row = Row.new("12 Oct 2011", "BuckyBox #0045 FROM J E SMITH ;Payment from J E SMITH #0023", "5")
      row.single_customer_match(distributor).should eq(@match)
    end
  end

  context :multiple_match do
    before do
      distributor.stub(:customers).and_return([
        mock_customer("0067", 0),
        @match1 = mock_customer("0999", 0),
        mock_customer("0001", 0),
        @match2 = mock_customer("0045", 0),
        mock_customer("8734", 0)
      ])
    end

    it "should match customer" do
      row = Row.new("12 Oct 2011", "BuckyBox #0045 FROM J E SMITH ;Payment from J E SMITH #0999", "5")
      row.customers_match(distributor).should eq([@match2, @match1])
    end
  end

  context :match_with_confidence do
    context :account_balance do
      before do
        distributor.stub(:customers).and_return([
          mock_customer("0067", 123.54),
          @match_0999 = mock_customer("0999", 200),
          mock_customer("0001", 30),
          @match_0045 = mock_customer("0045", 100),
          mock_customer("8734", 0)
        ])
      end
      let(:description){"BuckyBox #0045 FROM J E SMITH ;Payment from J E SMITH #0999"}
      let(:date){"12 Oct 2011"}

      it "should pick match with help of account balance" do
        row = Row.new(date, description, "200")
        row.single_customer_match(distributor).should eq(@match_0999)
      end

      it "should prefer matches which have a payment close to account balance" do
        Row.new(date, description, "80.00").single_customer_match(distributor).should eq(@match_0045)
        Row.new(date, description, "150.00").single_customer_match(distributor).should eq(@match_0999)
        Row.new(date, description, "120.00").single_customer_match(distributor).should eq(@match_0045)
      end
    end
  end

  describe ".customer_match" do
        let(:row){ Row.new("12 Oct 2011", "BuckyBox #0045 FROM J E SMITH ;Payment from J E SMITH #0999", "45.00")}

    it "should return 1.0 if references match exactly" do
      row.customer_match(mock_customer("0045")).should eq(0.8)
      row.customer_match(mock_customer("0999")).should eq(0.8)
    end

    it "should return number between 0.0 and 1.0 if nearly a match" do
      row.customer_match(mock_customer("0044")).should > 0.7
      row.customer_match(mock_customer("0919")).should < 0.9
    end
  end

  describe ".balance_match" do
    specify { Row.amount_match(0, 100).should eq(0.0)}
    specify { Row.amount_match(0, 450).should eq(0.0)}
    specify { Row.amount_match(100, 100).should eq(1.0)}
    specify { Row.amount_match(450, 450).should eq(1.0)}
    specify { Row.amount_match(149.99, 100).should eq(0.5001)}
    specify { Row.amount_match(150, 200).should eq(0.75)}
    specify { Row.amount_match(97, 100).should eq(0.97)}
    specify { Row.amount_match(150, 100).should eq(0.5)}
    specify { Row.amount_match(0, 100).should eq(0.0)}
    specify { Row.amount_match(200, 100).should eq(0.0)}
    specify { Row.amount_match(250, 100).should eq(0.0)}
    specify { Row.amount_match(350, 100).should eq(0.0)}
    specify { Row.amount_match(125, 100).should eq(0.75)}
    specify { Row.amount_match(175, 100).should eq(0.25)}
  end
end

def mock_customer(formated_number, balance = 0.0, orders = [0.0])
  # Setting the id below helps identify when a test fails
  mc = mock_model(Customer, formated_number: formated_number, id: formated_number)
  mc.stub_chain(:account, :balance, :to_f).and_return(balance)
  mc.stub(:orders).and_return(orders.collect{|o| stub(Order, price: o)})
  mc
end
