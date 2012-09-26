require 'spec_helper'

describe Webstore do
  let(:distributor) { mock_model Distributor }
  let(:box) { mock_model Box }

  describe '.start_order' do
    before do
      distributor.stub_chain(:boxes, :find) { box }
      @webstore_order = Webstore.start_order(distributor, 12, remote_ip: '192.168.1.8')
    end

    subject { @webstore_order }
  end
end
