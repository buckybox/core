require 'spec_helper'

describe Distributor do
  before :all do
    @distributor = Fabricate(:distributor, :email => 'BuckyBox@example.com')
  end

  specify { @distributor.should be_valid }
  specify { @distributor.parameter_name.should == @distributor.name.parameterize }
  specify { @distributor.email.should == 'buckybox@example.com' }
end

