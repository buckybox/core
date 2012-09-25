require 'spec_helper'

describe WebstoreOrder do
  let(:box)     { mock_model Box }
  let(:account) { mock_model Account }
  let(:route)   { mock_model Route }
  let(:order)   { mock_model Order }
  let(:webstore_order) { Fabricate.build(:webstore_order) }

  subject { webstore_order }

  context 'box information' do
    before do
      box.stub(:big_thumb_url) { 'box.jpg' }
      box.stub(:name) { 'Boxy' }
      box.stub(:price) { 12 }
      box.stub(:description) { 'A box.' }
      webstore_order.stub(:box) { box }
    end

    its(:thumb_url) { should eq('box.jpg') }
    its(:box_name) { should eq('Boxy') }
    its(:box_price) { should eq(12) }
    its(:box_description) { should eq('A box.') }
  end

  context 'route information' do
    before do
      route.stub(:name) { 'A Route' }
      route.stub(:fee) { 2 }
      account.stub(:route) { route }
      webstore_order.stub(:route) { route }
    end

    its(:route) { should eq(account.route) }
    its(:route_name) { should eq('A Route') }
    its(:route_fee) { should eq(2) }
  end

  context 'status' do
    specify { expect { webstore_order.customise_step }.to change(webstore_order, :status).to(:customise) }
    specify { expect { webstore_order.login_step }.to change(webstore_order, :status).to(:login) }
    specify { expect { webstore_order.delivery_step }.to change(webstore_order, :status).to(:delivery) }
    specify { expect { webstore_order.complete_step }.to change(webstore_order, :status).to(:complete) }
    specify { expect { webstore_order.placed_step }.to change(webstore_order, :status).to(:placed) }

    describe '#customised?' do

    end

    describe '#scheduled?' do

    end

    describe '#completed?' do

    end
  end

  context 'order information' do
    its(:order_extras_price) { should eq(1) }
    its(:order_price) { should eq(5) }
  end
end
