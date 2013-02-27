require 'spec_helper'

describe Extra do
  let(:extra) { Fabricate.build(:extra) }

  specify { extra.should be_valid }

  describe 'it should not strip one off extras when changing distributor yellow zone length' do
    before do
      Box.any_instance.stub(:extras_limit).and_return(3)
      @order = Fabricate(:active_everyday_order, extras_one_off: true)
      order_extra = Fabricate(:order_extra, order: @order)
      customer = @order.customer
      @distributor = customer.distributor
      
      @order.reload
      @date = Date.current

      @packing_list = PackingList.get(@distributor, @date)
      @package = @packing_list.packages.originals.find_or_create_by_order_id(@order.id)

      @packing_list2 = PackingList.get(@distributor, @date + 1.day)
      @package2 = @packing_list2.packages.originals.find_or_create_by_order_id(@order.id)
    end

    it 'should add extras to the first order' do
      @package.archived_extras.should_not be_blank
    end

    it 'should only add extras to the first order' do
      @package2.archived_extras.should be_blank
    end

    it 'should readd extras to an order if the package is destroyed' do
      @packing_list.destroy
      @packing_list2.destroy

      packing_list = PackingList.get(@distributor, @date)
      package = packing_list.packages.originals.find_or_create_by_order_id(@order.id)
      package.archived_extras.should_not be_blank

      packing_list2 = PackingList.get(@distributor, @date + 1.day)
      package2 = packing_list2.packages.originals.find_or_create_by_order_id(@order.id)
      package2.archived_extras.should be_blank
    end
  end
end
