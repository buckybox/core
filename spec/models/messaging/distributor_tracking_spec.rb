require 'spec_helper'

describe Messaging::Distributor do
  let(:distributor){ double('distributor').as_null_object }
  let(:distributor_tracking){ Messaging::Distributor.new(distributor) }
  let(:messaging){ Messaging::IntercomProxy.instance }

  describe '#tracking_after_create' do
    it 'passes call to IntercomProxy' do
      tracking_data = double("tracking_data")
      distributor_tracking.stub(:tracking_data).and_return(tracking_data)

      messaging.stub(:create_user).and_return(nil)
      messaging.should_receive(:create_user).with(tracking_data, Rails.env)

      distributor_tracking.tracking_after_create
    end
  end
end
