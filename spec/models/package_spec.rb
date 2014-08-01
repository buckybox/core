require 'spec_helper'

describe Package do
  let(:package) { Fabricate(:package) }

  specify { expect(package).to be_valid }

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

    specify { expect(@package.archived_address).to eq @address.join }
    specify { expect(@package.archived_address).to include @address.postcode }
    specify { expect(@package.archived_order_quantity).to eq @order.quantity }
    specify { expect(@package.archived_box_name).to eq @box.name }
    specify { expect(@package.archived_customer_name).to eq @address.customer.name }

    context :seperate_bucky_fee do
      it 'should archive the fee' do
        distributor = double('found_distributor')
        allow(distributor).to receive(:separate_bucky_fee?) { true }
        allow(distributor).to receive(:consumer_delivery_fee) { CrazyMoney.new(0.1) }
        allow(Distributor).to receive(:find_by_id).and_return(distributor)
        @package = Fabricate(:package, order: @order, packing_list: @package.packing_list)
        expect(@package.archived_consumer_delivery_fee_cents).to eq 10
      end

      it 'should not archive the fee' do
        Package.any_instance.stub_chain(:distributor, :separate_bucky_fee?).and_return(false)
        @package = Fabricate(:package, order: @order, packing_list: @package.packing_list)
        expect(@package.archived_consumer_delivery_fee_cents).to eq(0)
        allow_any_instance_of(Package).to receive(:distributor).and_call_original
      end
    end
  end
end
