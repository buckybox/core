require 'spec_helper'

describe Delivery do
  before { @delivery = Fabricate(:delivery) }

  specify { @delivery.should be_valid }

  context :status do
    specify { @delivery.status.should == 'pending' }
    specify { Fabricate.build(:delivery, :status => 'lame').should_not be_valid }
  end

  it "returns dates within a valid date range"
end
