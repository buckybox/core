require 'spec_helper'

describe StockItem do
  let(:stock_item) { Fabricate.build(:stock_item) }
  let(:distributor) { stock_item.distributor }

  specify { stock_item.should be_valid }

  describe '.from_list!' do
    context :invalid do
      specify { StockItem.from_list!(distributor, '').should be_false }
    end

    context :valid do
      before do
        @old_item_name = 'mice'

        # as an existing list item
        stock_item.name = @old_item_name
        stock_item.save

        @text = "oranges\nKiwi fruit\napples\npears\nApples"
      end

      specify { expect{ StockItem.from_list!(distributor, @text) }.should change(distributor.stock_items(true), :count).from(1).to(4) }

      specify { StockItem.from_list!(distributor, @text).map(&:name).include?(@old_item_name).should_not be_true }
      specify { StockItem.from_list!(distributor, @text).map(&:name).include?('Apples').should be_true }
      specify { StockItem.from_list!(distributor, @text).map(&:name).include?('Oranges').should be_true }
      specify { StockItem.from_list!(distributor, @text).map(&:name).include?('Pears').should be_true }
      specify { StockItem.from_list!(distributor, @text).map(&:name).include?('Kiwi Fruit').should be_true }
    end
  end

  describe '.to_list' do
    before do
      @distributor = Fabricate(:distributor)
      %w(oranges apples pears kiwi\ fruit).each { |name| Fabricate(:stock_item, name: name, distributor: @distributor) }
    end

    specify { StockItem.to_list(@distributor).should == "Apples\nKiwi Fruit\nOranges\nPears" }
  end
end
