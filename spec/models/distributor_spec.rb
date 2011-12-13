require 'spec_helper'

describe Distributor do
  before :all do
    @distributor = Fabricate(:distributor)
  end

  specify { @distributor.should be_valid }
  specify { @distributor.parameter_name.should == @distributor.name.parameterize }
end

