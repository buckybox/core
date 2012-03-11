require 'spec_helper'

describe Distributor do
  context :initialize do
    before { @distributor = Fabricate(:distributor, :email => ' BuckyBox@example.com ') }

    specify { @distributor.should be_valid }
    specify { @distributor.parameter_name.should == @distributor.name.parameterize }
    specify { @distributor.email.should == 'buckybox@example.com' }
  end

  context 'support email' do
    specify { Fabricate(:distributor, email: 'buckybox@example.com').support_email.should == 'buckybox@example.com' }
    specify { Fabricate(:distributor, support_email: 'support@example.com').support_email.should == 'support@example.com' }
  end
end
