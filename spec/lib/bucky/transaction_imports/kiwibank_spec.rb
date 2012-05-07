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

      def csv_string(csv_data)
        CSV.generate do |csv|
          csv_data.each do |row|
            csv << row
          end
        end
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
        Row.stub(:new)
        Row.should_receive(:new).with(date, description, amount).at_least(:once)
        Kiwibank.new.import_csv(csv_string(good_csv_data))
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
      
      let(:distributor){Fabricate(:distributor)}

      before(:all) do
        @kiwibank = Kiwibank.new
        @kiwibank.import(Kiwibank::TEST_FILE)
      end

      specify { @kiwibank.should be_valid}
      specify { @kiwibank.credit_rows.size.should eq(60)}
      specify { @kiwibank.debit_rows.size.should eq(16)}

      it "should present transactions with possible matches" do
        @kiwibank.transactions_for_display(distributor).size.should eq 76
      end
    end
  end
end
