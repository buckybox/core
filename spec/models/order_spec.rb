require 'spec_helper'

describe Order do
  before :all do
    @order = Fabricate(:order)
  end

  specify { @order.should be_valid }
end

