require 'spec_helper'

describe WebstoreOrder do
  let(:box) { mock_model Box }
  let(:route) { mock_model Route }
  let(:order) { mock_model Order }
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

    its(:thumb_url) { should eq(box.big_thumb_url) }
    its(:box_name) { should eq(box.name) }
    its(:box_price) { should eq(box.price) }
    its(:box_description) { should eq(box.description) }
  end

  context 'route information' do
    before do
      route.stub(:name) { 'A Route' }
      route.stub(:fee) { 2 }
      webstore_order.stub(:route) { route }
    end

    its(:route_name) { should eq(route.name) }
    its(:route_fee) { should eq(route.fee) }
  end

  context 'order information' do
    before do
      order.stub(:extras_price) { 2 }
      order.stub(:price) { 14 }
      webstore_order.stub(:order) { order }
    end

    its(:order_extras_price) { should eq(order.extras_price) }
    its(:order_price) { should eq(order.price) }
  end

  context 'state' do
    its(:completed?) { should be_false }
  end
end
