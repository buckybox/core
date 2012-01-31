require 'spec_helper'

describe Package do
  specify { Fabricate(:package).should be_valid }

  context :archive_data do
    before do
      @address = Fabricate(:address)
      @account = Fabricate(:account, :customer => @address.customer)
      @box = Fabricate(:box, :distributor => @account.distributor)
      @order = Fabricate(:active_order, :box => @box, :account => @account)
      @package = Fabricate(:package, :order => @order)
    end

    specify { @package.archived_address.should == @address.join(', ') }
    specify { @package.archived_order_quantity == @order.quantity }
    specify { @package.archived_box_name == @box.name }
    specify { @package.archived_box_price == @box.price }
    specify { @package.archived_customer_name == @address.customer.name }
  end
end
