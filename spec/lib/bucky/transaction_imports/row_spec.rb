require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Row do

  let(:distributor){ mock_model(Distributor)}

  context :single_match do
    before do
      distributor.stub(:customers).and_return([
        real_customer("0067", 0, [10.0], "Not", "Me"),
        real_customer("0999", 0, [20], "Jeremy", "Olliver"),
        real_customer("0001", 0, [16], "James", "Moriarty"),
        @match = real_customer("0045", 0, [5.0], "Jon" "Smith"),
        real_customer("8734", 0, [5.0], "Kate", "Barns")
      ])
    end

    it "should match customer" do
      row = Row.new("12 Oct 2011", "BuckyBox 0045 FROM J E SMITH ;Payment from J E SMITH 0023", "5")
      #row.single_customer_match(distributor).customer.should eq(@match)
    end
  end

  context :match_with_confidence do
    before do
      distributor.stub(:customers).and_return([
        real_customer("0067", -123.54),
        @match_0999 = real_customer("0999", -200, [20], "John", "Smith"),
        real_customer("0001", -30),
        @match_0045 = real_customer("0045", -100, [30], "James", "Rogers"),
        real_customer("8734", 0)
      ])
    end
    context :account_balance do
      let(:description){"BuckyBox FROM J E SMITH ;Payment from J E SMITH "}
      let(:date){"12 Oct 2011"}

      it "should pick match with help of account balance" do
        row = Row.new(date, description, "200")
        #row.single_customer_match(distributor).customer.should eq(@match_0999)
      end

      it "should prefer matches which have a payment close to account balance" do
        #Row.new(date, description, "80.00").single_customer_match(distributor).customer.should eq(@match_0045)
        #Row.new(date, description, "150.00").single_customer_match(distributor).customer.should eq(@match_0999)
        #Row.new(date, description, "120.00").single_customer_match(distributor).customer.should eq(@match_0045)
      end
    end

    context :name_match do
      let(:description){"BuckyBox FROM John E SMITH ;Payment from J E SMITH"}
      let(:description2){"BuckyBox 0213 FROM J E SMITH 5432 ;Payment from J E SMITH"}
      let(:date){"12 Oct 2011"}

      it "should pick match based on name" do
        row = Row.new(date, description, "200")
        #row.single_customer_match(distributor).customer.should eq(@match_0999)
      end
    end
  end

  describe ".match_confidence" do
    let(:row){ Row.new("12 Oct 2011", "BuckyBox 0045 FROM J E SMITH ;Payment from J E SMITH 0999", "45.00")}

    it "should return 1.0 if references match exactly" do
      #row.match_confidence(mock_customer("0045")).should eq(0.8)
      #row.match_confidence(mock_customer("0999")).should eq(0.8)
    end

    it "should return number between 0.0 and 1.0 if nearly a match" do
      #row.match_confidence(mock_customer("0044")).should > 0.7
      #row.match_confidence(real_customer("0919")).should < 0.9
    end
  end

  describe ".match_previous_matches" do
    let(:description){"BuckyBox 0045 FROM J E SMITH ;Payment from J E SMITH 0999"}
    let(:row){ Row.new("12 Oct 2011", description, "45.00")}

    before do
      distributor.stub(:customers).and_return([
        @c1 = mock_customer_with_history("0321", {previous_matches: [
          description,
          "one off payment from Jack Smith",
          "buckybox stuff"
        ]}),
          @c2 = mock_customer_with_history("0123", {previous_matches: [
            "one off payment from J STOAK;",
            "I HATE MAKING THIS STUFF UP"
        ]}),
      ])


    end

    it "should match customer based on previous matches set by distributor" do
      #row.match_previous_matches(distributor).should eq(@c1)
    end
  end

  describe ".find_duplicates" do
    let(:description){"BuckyBox 0045 FROM J E SMITH ;Payment from J E SMITH 0999"}
    let(:date){"12 Oct 2011"}
    let(:amount){"45.00"}
    let(:row){ Row.new(date, description, amount)}

    before do
      distributor.stub(:find_duplicate_import_transactions).with(Date.parse(date), description, amount.to_f).and_return(mock_model(ImportTransaction, {date: Date.parse(date), description: description, amount: amount}))
    end

    it "should detect duplicates" do
      #row.duplicate?(distributor).should be_true
    end
  end

  describe ".balance_match" do
    specify { Row.amount_match(0, -100).should eq(0.0)}
    specify { Row.amount_match(0, -450).should eq(0.0)}
    specify { Row.amount_match(100, -100).should eq(1.0)}
    specify { Row.amount_match(450, -450).should eq(1.0)}
    specify { Row.amount_match(149.99, -100).should eq(0.5001)}
    specify { Row.amount_match(150, -200).should eq(0.75)}
    specify { Row.amount_match(97, -100).should eq(0.97)}
    specify { Row.amount_match(150, -100).should eq(0.5)}
    specify { Row.amount_match(0, -100).should eq(0.0)}
    specify { Row.amount_match(200, -100).should eq(0.0)}
    specify { Row.amount_match(250, -100).should eq(0.0)}
    specify { Row.amount_match(350, -100).should eq(0.0)}
    specify { Row.amount_match(125, -100).should eq(0.75)}
    specify { Row.amount_match(175, -100).should eq(0.25)}
    specify { Row.amount_match(100, -100).should eq(1.00)}
    specify { Row.amount_match(100, 100).should eq(0)}
    specify { Row.amount_match(10, 2).should eq(0)}
  end
end

def mock_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  # Setting the id below helps identify when a test fails
  mc = mock_model(Customer, formated_number: formated_number, id: formated_number)
  mc.stub_chain(:account, :balance, :to_f).and_return(balance)
  mc.stub(:orders).and_return(orders.collect{|o| stub(Order, price: o)})
  mc.stub(:first_name).and_return(first_name) if first_name.present?
  mc.stub(:last_name).and_return(last_name) if last_name.present?
  mc
end

def real_customer(formated_number, balance = 0.0, orders = [0.0], first_name = nil, last_name = nil)
  c = Fabricate.build(:customer, number: formated_number.to_i)
  c.stub_chain(:account, :balance, :to_f).and_return(balance)
  c.stub(:orders).and_return(orders.collect{|o| stub(Order, price: o)})
  c.first_name = first_name unless first_name.blank?
  c.last_name = last_name unless last_name.blank?
  c
end

def mock_customer_with_history(formated_number, opts = {})
  mc = mock_customer(formated_number)
  previous_matches = opts.delete(:previous_matches)
  mc.stub(:previous_matches).and_return(previous_matches)
  mc
end
