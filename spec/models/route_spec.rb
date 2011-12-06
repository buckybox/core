require 'spec_helper'

describe Route do
  before :all do
    @route = Fabricate(:route)
  end

  specify { @route.should be_valid }
end

