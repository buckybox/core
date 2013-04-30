require 'fast_spec_helper'
require_model 'csv_row_generator'
require_model 'package_csv_row_generator'

describe PackageCsvRowGenerator do
  let(:order) do
    double('order',
      route_name: 'rname',
      id: 1,
      customer: customer,
    )
  end
  let(:delivery) do
    double('delivery',
      formated_delivery_number: 01,
      status: 'pak',
    )
  end
  let(:package) do
    double('package',
      order: order,
      delivery: delivery,
      id: 1,
      date: Date.parse('2013-04-11'),
      archived_address_details: address,
      short_code: 'c',
      archived_box_name: 'bname',
      archived_substitutions: 'sub',
      archived_exclusions: 'ex',
      extras_description: 'exd',
      price: 10.00,
      archived_consumer_delivery_fee: 1.00,
      total_price: 11.00,
      status: 'del',
    )
  end
  let(:customer) do
    double('customer',
      number: 1,
      first_name: 'fname',
      last_name: 'lname',
      new?: true,
      email: 'em@ex.com',
      special_order_preference: 'pref',
    )
  end
  let(:address) do
    double('address',
      phone_1: 8888,
      address_1: 'street 1',
      address_2: 'apt 1',
      suburb: 'sub',
      city: 'city',
      postcode: 123,
      delivery_note: 'note',
    )
  end
  let(:csv_row_generator) { PackageCsvRowGenerator.new(package) }

  describe '#generate' do
    it 'generates a array for conversion to csv row' do
      csv_row_generator.generate.should == ["rname", 1, nil, 1, 1, "11 Apr 2013", 1, "fname", "lname", 8888, "NEW", "street 1", "apt 1", "sub", "city", 123, "note", "c", "bname", "sub", "ex", "exd", 10.0, 1.0, 11.0, "em@ex.com", "pref", "del", "pak"]
    end
  end
end
