require_relative '../../../app/models/webstore/session'

describe Webstore::Session do
  let(:order)          { double('order', id: 1) }
  let(:customer)       { double('customer', id: 2) }
  let(:order_class)    { double('order_class', find: order) }
  let(:customer_class) { double('customer_class', find: customer) }
  let(:args)           { { order_class: order_class, customer_class: customer_class } }
  let(:session)        { Webstore::Session.new(args) }

  describe '.deserialize' do
    it 'creates a session model from a session hash' do
      new_session = double('session')
      Webstore::Session.stub(:new) { new_session }
      Webstore::Session.deserialize(args).should eq(new_session)
    end
  end

  describe '#serialize' do
    it 'returns a hash of the session object' do
      session.serialize.should eq({ order_id: 1, customer_id: 2 })
    end
  end
end
