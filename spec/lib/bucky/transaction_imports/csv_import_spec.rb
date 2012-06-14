require 'spec_helper'

include Bucky::TransactionImports

shared_examples_for "a csv import" do
  describe ".import_csv" do
    before(:all) do
      @rows = described_class.new.import_csv(described_class::TEST_FILE)
    end

    it "should import all rows" do
      @rows.size.should eq(expected_row_count)
    end

    it "should correctly parse date" do
      @rows.first.date.should eq(Date.parse(expected_date))
    end
  end
end

describe Bnz do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){44}
    let(:expected_date){"2011/12/12"}
  end
end

describe Kiwibank do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){76}
    let(:expected_date){"2012/04/03"}
  end
end

describe National do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){60}
    let(:expected_date){"2012/06/07"}
  end
end

describe Paypal do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){1}
    let(:expected_date){"2012/04/23"}
  end
end

describe StGeorgeAu do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){92}
    let(:expected_date){"2012/04/18"}
  end
end
