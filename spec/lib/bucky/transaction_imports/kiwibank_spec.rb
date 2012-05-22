require 'spec_helper'

include Bucky::TransactionImports

describe Bucky::TransactionImports::Kiwibank do

  describe ".import" do
    context :with_test_csv do
      let(:good_csv_data) do
        csv = []
        csv << ["38-9009-0055594-00"]
        csv << ["12 Oct 2010", "INTEREST CREDIT ;", "", "0.5"]
        csv << ["13 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "50"]
        csv << ["13 Oct 2010", "IRD WITHHOLDING TAX 17.500% ;", "", "-0.06"]
        csv << ["14 Oct 2010", "FROM SOCIAL CAPITAL LIMITED ;Social Capit Wages", "", "111.11"]
        csv << ["14 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "50"]
        csv << ["15 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "50"]
        csv << ["15 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "50"]
        csv
      end

      let(:bad_csv_data) do
        csv = []
        csv << ["38-9009-0055594-00"]
        csv << ["12 Oct 2010", "INTEREST CREDIT ;", "", ""]
        csv << ["13 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "#!"]
        csv << ["13 Oct 2010", "IRD WITHHOLDING TAX 17.500% ;", "", "-a0.06"]
        csv << ["", "FROM SOCIAL CAPITAL LIMITED ;Social Capit Wages", "", "23"]
        csv << ["14 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", ""]
        csv << ["15 Oct 2010", "", "", "50"]
        csv << ["15 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", "34.34.3350"]
        csv << ["15 Oct 2010", "AP#5577411 FROM J E SMITH ;Payment from J E SMITH", "", ""]
        csv << ["", "", "", ""]
        csv << ["", "FROM SOCIAL CAPITAL LIMITED ;Social Capit Wages", "", "111.11"]
        csv
      end

      it "should return correct number of transaction rows" do
        Kiwibank.new.import_csv(csv_string(good_csv_data)).size.should eq(7)
      end

      it "should return rows" do
        Kiwibank.new.import_csv(csv_string(good_csv_data)).each do |row|
          row.should be_a(Row)
        end
      end

      it "should create rows" do
        date = good_csv_data[1][0]
        description = good_csv_data[1][1]
        amount = good_csv_data[1][3]
        parser = Kiwibank.new
        Row.stub(:new)
        Row.should_receive(:new).with(date, description, amount, 1, parser).at_least(:once)
        parser.import_csv(csv_string(good_csv_data))
      end

      it "should create valid rows" do
        importer = Kiwibank.new
        importer.import_csv(csv_string(good_csv_data))
        importer.should be_valid
      end

      it "should return errors" do
        importer = Kiwibank.new
        importer.import_csv(csv_string(bad_csv_data))
        importer.should_not be_valid
      end
    end

    context :full_test do

      context :test_file do
        let(:distributor){Fabricate(:distributor)}

        before(:all) do
          @kiwibank = Kiwibank.new
          @kiwibank.import(Kiwibank::TEST_FILE)
        end

        specify { @kiwibank.should be_valid}
        specify { @kiwibank.credit_rows.size.should eq(60)}
        specify { @kiwibank.debit_rows.size.should eq(16)}

        it "should present transactions with possible matches" do
          #@kiwibank.transactions_for_display(distributor).import_transactions.size.should eq 76
        end
      end

      context :test_data do
        let!(:distributor){Fabricate(:distributor)}
        let!(:route){Fabricate(:route, distributor: distributor)}
        let!(:box_small){Fabricate(:box, distributor: distributor, name: "Small Box", price: 20)}
        let!(:box_large){Fabricate(:box, distributor: distributor, name: "Large Box", price: 50)}
        let!(:customer0001){
          c=Fabricate(:customer, distributor: distributor, first_name: "John", last_name: "Smith", number: 1)
          c.account.change_balance_to(-100)
          c
        }
        let!(:order0001){Fabricate(:active_order, account: customer0001.account, box: box_large)}
        let!(:customer0005){
          c=Fabricate(:customer, distributor: distributor, first_name: "James", last_name: "Robberts", number: 5)
          c.account.change_balance_to(-120)
          c
        }
        let!(:order0005){Fabricate(:active_order, account: customer0005.account, box: box_small)}
        let!(:customer0011){
          c=Fabricate(:customer, distributor: distributor, first_name: "Kate", last_name: "Barns", number: 11)
          c.account.change_balance_to(-20)
          c
        }
        let!(:order0011){Fabricate(:active_order, account: customer0011.account, box: box_small)}
        let(:csv){
          csv = CsvData.new
          csv.a "12 Oct 2011", "John Smith", "20"
          csv.a "13 Oct 2011", "Kate Barns 0011 small box", "20"
          csv.a "15 Oct 2011", "EFTPOS blah 12:124.435", "-16.23"
          csv.a "15 Oct 2011", "James 0005 small box", "20"
          csv.a "29 Oct 2011", "large vegys 0001", "50"
          csv.a "18 Nov 2011", "Kate Barns 0011", "20"
          csv
        }

        #before(:each) do
        #  @kiwibank = Kiwibank.new
        #  @kiwibank.import_csv(csv.csv_string)
        #  @transaction_list = @kiwibank.transactions_for_display(distributor)
        #end

        #it "should find johns payments" do
        #  johns_transactions = @transaction_list.import_transactions.select{|t| t.customer == customer0001}
        #  puts @transaction_list.import_transactions.collect(&:inspect)
        #  johns_transactions.size.should eq(2)
        #end

        #it "should find james payments" do
        #  james_transactions = @transaction_list.import_transactions.select{|t| t.customer == customer0005}
        #  james_transactions.size.should eq(2)
        #end

        #it "should find kates payments" do
        #  kates_transactions = @transaction_list.import_transactions.select{|t| t.customer == customer0011}
        #  kates_transactions.size.should eq(2)
        #end
      end
    end
  end

  def csv_string(csv_data)
    CSV.generate do |csv|
      csv_data.each do |row|
        csv << row
      end
    end
  end
end

class CsvData
  attr_accessor :csv_data

  require 'csv'

  def a(date, description, amount)
    @csv_data ||= []
    @csv_data << [date, description, "", amount]
  end

  def csv_string
    CSV.generate do |csv|
      @csv_data.each do |row|
        csv << row
      end
    end
  end
end
