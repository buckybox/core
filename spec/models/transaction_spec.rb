require 'spec_helper'

describe Transaction do
  let(:transaction) { Transaction.make }

  specify { transaction.should be_valid }

  context :kind do
    %w(delivery payment amend).each do |k|
      specify { Transaction.make(:kind => k).should be_valid }
    end

    specify { Transaction.make(:kind => 'something').should_not be_valid }
  end
end

