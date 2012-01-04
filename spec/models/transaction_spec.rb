require 'spec_helper'

describe Transaction do
  before { @transaction = Fabricate(:transaction) }

  specify { @transaction.should be_valid }

  context :kind do
    %w(delivery payment amend).each do |k|
      specify { Fabricate.build(:transaction, :kind => k).should be_valid }
    end

    specify { Fabricate.build(:transaction, :kind => 'order').should_not be_valid }
  end

  it "updates account balance after edit" do
    @transaction.account.should_receive(:recalculate_balance!)
    @transaction.save
  end

  it "updates account balance after destroy" do
    @transaction.account.should_receive(:recalculate_balance!)
    @transaction.destroy
  end
end

