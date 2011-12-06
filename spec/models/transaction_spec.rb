require 'spec_helper'

describe Transaction do
  before :all do
    @transaction = Fabricate(:transaction)
  end

  specify { @transaction.should be_valid }
end

