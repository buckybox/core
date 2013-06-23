require 'spec_helper'

describe Webstore::CartPersistance do
  let(:args)             { { collected_data: { order: 'value' } } }
  let(:cart_persistance) { Webstore::CartPersistance.new(args) }

  context '#collected_data' do
    it 'gives hash that can be accessed with string keys', loads_rails: true do
      cart_persistance.collected_data['order'].should eq('value')
    end

    it 'gives hash that can be accessed with symbol keys', loads_rails: true do
      cart_persistance.collected_data[:order].should eq('value')
    end
  end
end
