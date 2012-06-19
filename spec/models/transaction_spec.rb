require 'spec_helper'

describe Transaction do
  let(:transaction) { Fabricate.build(:transaction) }

  specify { transaction.should be_valid }
end
