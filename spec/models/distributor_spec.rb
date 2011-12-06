require 'spec_helper'

describe Distributor do
  before :all do
    @distributor = Fabricate(:distributor)
  end

  specify { @distributor.should be_valid }
end

