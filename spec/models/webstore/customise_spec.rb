require 'fast_spec_helper'
stub_constants %w(Extra)
require_relative '../../../app/models/webstore/customise'

describe Webstore::Customise do
  let(:order)     { double('order') }
  let(:args)      { { order: order } }
  let(:customise) { Webstore::Customise.new(args) }

  describe '#dislikes?' do
    it 'returns true if the order can have dislikes' do
      customise.dislikes?.should eq(true)
    end
  end

  describe '#likes?' do
    it 'returns true if the order can have likes' do
      customise.likes?.should eq(true)
    end
  end

  describe '#extras_allowed?' do
    it 'returns true if the order can have extras' do
      customise.extras_allowed?.should eq(true)
    end
  end

  describe '#extras_unlimited?' do
    it 'returns true if the order can have unlimited extras' do
      customise.extras_unlimited?.should eq(false)
    end
  end

  describe '#exclusions_limit' do
    it 'returns the maximum number of exclusions this order can have' do
      customise.exclusions_limit.should eq(3)
    end
  end

  describe '#substitutions_limit' do
    it 'returns the maximum number of substitutions this order can have' do
      customise.substitutions_limit.should eq(3)
    end
  end

  describe '#extras_limit' do
    it 'returns the maximum number of extras this order can have' do
      customise.extras_limit.should eq(3)
    end
  end

  describe '#stock_list' do
    it 'returns a list of items that can be chosen for exclusions or substitutions on the order' do
      customise.stock_list.should eq(['Apples', 'Banannas', 'Oranges', 'Grapes', 'Eggs', 'Coffee'])
    end
  end

  describe '#extras' do
    it 'returns a list of extras that can be added to the order' do
      extras = [double('extra')]
      Extra.stub(:limit) { extras }
      customise.extras.should eq(extras)
    end
  end
end
