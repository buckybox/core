require 'spec_helper'

describe Transaction do
  before { @transaction = Fabricate(:transaction) }

  specify { @transaction.should be_valid }

  context :kind do
    %w(delivery payment amend).each do |k|
      specify { Fabricate.build(:transaction, :kind => k).should be_valid }
    end

    specify { Fabricate.build(:transaction, :kind => 'something').should_not be_valid }
  end
end

