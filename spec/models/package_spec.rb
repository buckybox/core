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
  end
end
