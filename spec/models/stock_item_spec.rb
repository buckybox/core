require 'spec_helper'

describe StockItem do
  let(:stock_item) { Fabricate.build(:stock_item) }
  let(:distributor) { stock_item.distributor }

  specify { stock_item.should be_valid }

  describe '.from_list!' do
    before do
      @old_item_name = 'mice'

      # as an existing list item
      stock_item.name = @old_item_name
      stock_item.save

      @text = "oranges\napples\npears\nApples"
    end

    specify { expect{ StockItem.from_list!(distributor, '') }.should raise_error }
    specify { expect{ StockItem.from_list!(distributor, @text) }.should change(distributor.stock_items(true), :count).from(1).to(3) }

    specify { StockItem.from_list!(distributor, @text).map(&:name).include?(@old_item_name).should_not be_true }
    specify { StockItem.from_list!(distributor, @text).map(&:name).include?('apples').should be_true }
    specify { StockItem.from_list!(distributor, @text).map(&:name).include?('oranges').should be_true }
    specify { StockItem.from_list!(distributor, @text).map(&:name).include?('pears').should be_true }
  end

  describe '.to_list' do
    before do
      @distributor = Fabricate(:distributor)
      %w(oranges apples pears).each { |name| Fabricate(:stock_item, name: name, distributor: @distributor) }
    end

    specify { StockItem.to_list(@distributor).should == "apples\noranges\npears" }
  end
end
