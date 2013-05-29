require 'spec_helper'

describe Package do
  let(:package) { Fabricate(:package) }

  specify { package.should be_valid }

  context :archive_data do
    before do
      @distributor = Fabricate(:distributor, consumer_delivery_fee_cents: 10)
      @customer    = Fabricate(:customer, distributor: @distributor)
      @address     = Fabricate(:address_with_associations)
      @account     = Fabricate(:account, customer: @address.customer)
      @box         = Fabricate(:box, distributor: @account.distributor)
      @order       = Fabricate(:order, box: @box, account: @account)
      @package     = Fabricate(:package, order: @order)
    end

    specify { @package.archived_address.should == @address.join(', ') }
    specify { @package.archived_order_quantity.should == @order.quantity }
    specify { @package.archived_box_name.should == @box.name }
    specify { pending "HKD/NZD currency issue"; @package.archived_box_price.should == @box.price }
    specify { @package.archived_customer_name.should == @address.customer.name }

    context :seperate_bucky_fee do
      it 'should archive the fee' do
        distributor = double('found_distributor')
        distributor.stub(:separate_bucky_fee?) { true }
        distributor.stub(:consumer_delivery_fee) { Money.new(10) }
        Distributor.stub(:find_by_id).and_return(distributor)
        @package = Fabricate(:package, order: @order, packing_list: @package.packing_list)
        @package.archived_consumer_delivery_fee_cents.should == 10
      end

      it 'should not archive the fee' do
        Package.any_instance.stub_chain(:distributor, :separate_bucky_fee?).and_return(false)
        @package = Fabricate(:package, order: @order, packing_list: @package.packing_list)
        @package.archived_consumer_delivery_fee_cents.should == 0
        Package.any_instance.unstub(:distributor)
      end
    end
  end
end
