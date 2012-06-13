require 'spec_helper'

include Bucky::TransactionImports

shared_examples_for "a csv import" do
  describe ".import_csv" do
    let(:rows){described_class.new.import_csv(described_class::TEST_FILE)}

    it "should import all rows" do
      rows.size.should eq(expected_row_count)
    end
  end
end

describe Bnz do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){44}
  end
end

describe Kiwibank do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){76}
  end
end

describe National do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){60}
  end
end

describe Paypal do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){1}
  end
end

describe StGeorgeAu do
  it_should_behave_like "a csv import" do
    let(:expected_row_count){92}
  end
end
