require 'spec_helper'

describe Package do
  let(:package) { Fabricate.build(:package) }

  specify { package.should be_valid }

  context :archive_data do
    before do
      @address = Fabricate(:address_with_associations)
      @account = Fabricate(:account, customer: @address.customer)
      @box = Fabricate(:box, distributor: @account.distributor)
      @order = Fabricate(:order, box: @box, account: @account)
      @package = Fabricate(:package, order: @order)
    end

    specify { @package.archived_address.should == @address.join(', ') }
    specify { @package.archived_order_quantity == @order.quantity }
    specify { @package.archived_box_name == @box.name }
    specify { @package.archived_box_price == @box.price }
    specify { @package.archived_customer_name == @address.customer.name }
  end

  context '#self.calculated_price' do
    # Default box price is $10
    before { @box = Fabricate(:box) }

    PRICE_PERMUTATIONS = [
      { discount: 0.05, fee: 5, quantity: 5, calculated_price: 14.25 },
      { discount: 0.05, fee: 5, quantity: 1, calculated_price: 14.25 },
      { discount: 0.05, fee: 0, quantity: 5, calculated_price:  9.50 },
      { discount: 0.05, fee: 0, quantity: 1, calculated_price:  9.50 },
      { discount: 0.00, fee: 5, quantity: 5, calculated_price: 15.00 },
      { discount: 0.00, fee: 5, quantity: 1, calculated_price: 15.00 },
      { discount: 0.00, fee: 0, quantity: 5, calculated_price: 10.00 },
      { discount: 0.00, fee: 0, quantity: 1, calculated_price: 10.00 }
    ]

    PRICE_PERMUTATIONS.each do |pp|
      context "where discount is #{pp[:discount]}, fee is #{pp[:fee]}, and quantity is #{pp[:quantity]}" do
        before do
          @route = Fabricate(:route, fee: pp[:fee])
          @customer = Fabricate(:customer, discount: pp[:discount], route: @route)
          @order = Fabricate(:order, quantity: pp[:quantity], account: @customer.account)
        end

        specify { Package.calculated_price(@box, @route, @customer).should == pp[:calculated_price] }
      end
    end
  end

  context '#individual_price' do
    before do
      @price    = package.archived_box_price
      @fee      = package.archived_route_fee
      @discount = package.archived_customer_discount

      box = package.box
      box.price = 25
      box.save

      route = package.route
      route.fee = 10
      route.save

      customer = package.customer
      customer.discount = 0.2
      customer.save

      @new_price    = box.price
      @new_fee      = route.fee
      @new_discount = customer.discount
    end

    specify { package.individual_price.should == Package.calculated_price(@price, @fee, @discount) }
    specify { package.individual_price.should_not == Package.calculated_price(@new_price, @new_fee, @new_discount) }
  end

  context '.csv_headers' do
    specify { Package.csv_headers.size.should == 24 }
  end

  context '#to_csv' do
    specify { package.to_csv[0].should == package.route.name }
    specify { package.to_csv[3].should == package.order.id }
    specify { package.to_csv[4].should == package.id }
    specify { package.to_csv[5].should == package.date.strftime("%-d %b %Y") }
    specify { package.to_csv[6].should == package.customer.number }
    specify { package.to_csv[7].should == package.customer.first_name }
    specify { package.to_csv[23].should == package.customer.email }
  end
end
