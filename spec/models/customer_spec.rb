require 'spec_helper'

describe Customer do
  let(:customer) { Fabricate.build(:customer) }

  specify { customer.should be_valid }

  context 'a customer' do
    before { @customer = Fabricate(:customer) }

    context 'initializing' do
      specify { @customer.address.should_not be_nil }
      specify { @customer.account.should_not be_nil }
      specify { @customer.number.should_not be_nil }
    end

    context 'email' do
      before do
        @customer.email = ' BuckyBox@Example.com '
        @customer.save
      end

      specify { @customer.email.should == 'buckybox@example.com' }
    end

    context 'number' do
      before { @customer.number = -1 }
      specify { @customer.should_not be_valid }
    end

    context 'random password' do
      before do
        @customer.password = @customer.password_confirmation = ''
        @customer.save
      end

      specify { @customer.password.should_not be_nil }
      specify { @customer.randomize_password.length == 12 }
      specify { Customer.random_string.should_not == Customer.random_string }
    end

    context 'full name' do
      describe '#name' do
        describe 'with only first name' do
          specify { @customer.name.should == @customer.first_name }
        end

        describe 'with both first and last name' do
          before { @customer.last_name = 'Lastname' }
          specify { @customer.name.should == "#{@customer.first_name} #{@customer.last_name}" }
        end
      end

      describe '#name=' do
        before { @customer.name= 'John Smith' }
        specify { @customer.first_name.should == 'John' }
        specify { @customer.last_name.should == 'Smith' }
      end
    end

    context 'when using tags' do
      before :each do
        @customer.tag_list = 'dog, cat, rain'
        @customer.save
      end

      specify { @customer.tags.size.should == 3 }
      specify { @customer.tag_list.sort.should == %w(cat dog rain) }
    end
  end

  context 'when searching' do
    before :each do
      address = Fabricate(:address_with_associations, city: 'Edinburgh')
      customer2 = address.customer
      customer2.first_name = 'Smith'
      customer2.save

      Fabricate(:address_with_associations, city: 'Edinburgh')
      Fabricate(:customer, last_name: 'Smith')
      Fabricate(:customer, first_name: 'John', last_name: 'Smith')
    end

    specify { Customer.search('Edinburgh').size.should == 2 }
    specify { Customer.search('Smith').size.should == 3 }
    specify { Customer.search('John').size.should == 1 }
  end

  context '#new?' do
    before { @customer = Fabricate(:customer) }

    context 'customer has 0 deliveries' do
      before { @customer.deliveries.stub(:size).and_return(0) }
      specify { @customer.new?.should be_true }
    end

    context 'customer has 1 delivery' do
      before { @customer.deliveries.stub(:size).and_return(1) }
      specify { @customer.new?.should be_true }
    end

    context 'customer has 2 deliveries' do
      before { @customer.deliveries.stub(:size).and_return(2) }
      specify { @customer.new?.should be_false }
    end
  end

  describe '#order_with_next_delivery' do
    context 'with orders' do
      before do
        @o1 = Fabricate.build(:active_recurring_order)
        @o2 = Fabricate.build(:active_recurring_order)
        @o3 = Fabricate.build(:active_recurring_order)

        customer.stub_chain(:account, :active_orders).and_return([@o1, @o2, @o3])
      end

      specify { customer.order_with_next_delivery.should == @o3 }

      context 'and order without next delivery' do
        before do
          @o4 = Fabricate.build(:order)
          @o4.stub_chain(:schedule, :next_occurrence).and_return(nil)
          customer.stub_chain(:account, :active_orders).and_return([@o1, @o2, @o3])
        end

        specify { customer.order_with_next_delivery.should == @o3 }
      end
    end

    context 'without orders' do
      before { customer.stub_chain(:account, :active_orders).and_return([]) }
      specify { customer.order_with_next_delivery.should == nil }
    end
  end

  describe '#next_delivery_time' do
    before do
      @order = Fabricate.build(:active_recurring_order)
      customer.stub(:order_with_next_delivery).and_return(@order)
    end

    specify { customer.next_delivery_time.should == @order.schedule.next_occurrence }
  end

  describe '.import' do
    let(:customer){ Fabricate.build(:customer) }

    it "should import customer with all fields" do
      route = mock_model(Route)
      route.stub_chain(:schedule, :include?).and_return(true)

      boxes = []
      box = box_mock({box_type: "Rural Van", extras_unlimited?: true})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("Rural Van").and_return(mock_model('Box', extras_unlimited?: true))
      boxes << box

      box = box_mock({box_type: "City Van", extras_unlimited?: true})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("City Van").and_return(mock_model('Box', extras_unlimited?: true))
      boxes << box

      Distributor.any_instance.stub(:find_extra_from_import).and_return(mock_model('Extra'))

      attrs = {
        first_name: 'Jordan',
        last_name: 'Carter',
        email: 'jc@example.com',
        discount: 0.1,
        number: 1234,
        notes: 'Good one dave, your a legend Dave',
        account_balance: 80.65,
        delivery_route: "Rural Van",
        delivery_address_line_1: 'camp site 2c',
        delivery_address_line_2: 'next to the toilet',
        delivery_suburb: 'Solway',
        delivery_city: 'Masterton',
        delivery_postcode: '1234567',
        delivery_instructions: 'by the zips please',
        phone_1: '0800 999 666 333',
        phone_2: '0800 BOWIES IN SPACE',
        tags: ["Flight of the concords", "rock"],
        boxes: boxes
      }
      import_customer = customer_mock(attrs)

      customer.import(import_customer, route)

      customer.first_name.should eq(attrs[:first_name])
      customer.last_name.should eq(attrs[:last_name])
      customer.email.should eq(attrs[:email])
      customer.route_id.should eq(route.id)
      customer.number.should eq(attrs[:number])
      customer.notes.should eq(attrs[:notes])
      customer.discount.should eq(attrs[:discount])
      customer.tag_list.should eq(["flight-of-the-concords", "rock"])

      address = customer.address
      address.phone_1.should eq(attrs[:phone_1])
      address.phone_2.should eq(attrs[:phone_2])
      address.address_1.should eq(attrs[:delivery_address_line_1])
      address.address_2.should eq(attrs[:delivery_address_line_2])
      address.suburb.should eq(attrs[:delivery_suburb])
      address.city.should eq(attrs[:delivery_city])
      address.postcode.should eq(attrs[:delivery_postcode])
      address.delivery_note.should eq(attrs[:delivery_instructions])

      account = customer.account
      account.balance.should eq(attrs[:account_balance])

      0.upto(1).to_a.each do |n|
        order = customer.orders[n]
        box = boxes[n]
      end
    end
  end

  def customer_mock(opts={})
    customer = double("Bucky::Import::Customer")
    attrs = {
      first_name: 'Jordan',
      last_name: 'Carter',
      email: 'jc@example.com',
      discount: 0.1,
      number: 1234,
      notes: 'Good one dave, your a legend Dave',
      account_balance: 80.65,
      delivery_route: "Rural Van",
      delivery_address_line_1: 'camp site 2c',
      delivery_address_line_2: 'next to the toilet',
      delivery_suburb: 'Solway',
      delivery_city: 'Masterton',
      delivery_postcode: '1234567',
      delivery_instructions: 'by the zips please',
      phone_1: '0800 999 666 333',
      phone_2: '0800 BOWIES IN SPACE',
      tags: ["Flight of the concords", "rock"],
      boxes: 2.times.collect{box_mock},
    }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Customer }
    attrs.merge(extras).each do |key, value|
      customer.stub(key).and_return(value)
    end

    customer
  end

  def box_mock(opts={})
    box = double("Bucky::Import::Box")
    attrs = {
      box_type: "Rural Van",
      dislikes: "Onions",
      likes: "Carrots",
      delivery_frequency: "weekly",
      delivery_days: "Monday, Tuesday, Friday",
      next_delivery_date: "23-Mar-2013",
      extras_limit: 3,
      extras_unlimited?: false,
      extras_recurring?: true,
      extras: 2.times.collect{extra_mock}
          }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Box }
    attrs.merge(extras).each do |key, value|
      box.stub(key).and_return(value)
    end

    box
  end

  def extra_mock(opts={})
    extra = double("Bucky::Import::Extra")
    attrs = {
      count: 1,
      name: "Bacon",
      unit: "7 slices"
          }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Extra }
    attrs.merge(extras).each do |key, value|
      extra.stub(key).and_return(value)
    end

    extra
  end
end
