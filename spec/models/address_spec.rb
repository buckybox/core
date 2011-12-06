require 'spec_helper'

describe Address do
  before :all do
    @address = Fabricate(:address)
  end

  specify { @address.should be_valid }
end
