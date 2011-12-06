require 'spec_helper'

describe Customer do
  before :all do
    @customer = Fabricate(:customer)
  end

  specify { @customer.should be_valid }
end
