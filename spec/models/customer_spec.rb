require 'spec_helper'

describe Customer do
  def customer_mock(opts={})
    customer = double("Bucky::Import::Customer")
    attrs = {
      first_name: 'Jordan',
      last_name: 'Carter',
      email: 'jc@example.com',
      discount: 0.1,
      currency: 'NZD',
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
      mobile_phone: '0800 999 666 333',
      home_phone: '0800 BOWIES IN SPACE',
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

  let(:customer) { Fabricate(:customer) }

  specify { customer.should be_valid }

  context :create_with_account_under_limit do
    let(:distributor) { Fabricate(:distributor, default_balance_threshold_cents: -50000, has_balance_threshold: true) }

    it 'should create a valid customer' do
      c = distributor.customers.create({"first_name"=>"Jordan", "last_name"=>"Carter", "tag_list"=>"", "email"=>"jordan+3@buckybox.com", "address_attributes"=>{"mobile_phone"=>"", "home_phone"=>"", "work_phone"=>"", "address_1"=>"43a Warwick St", "address_2"=>"Wilton", "suburb"=>"Wellington", "city"=>"Wellington", "postcode"=>"6012", "delivery_note"=>""}, "balance_threshold"=>"1.00", "discount"=>"0", "special_order_preference"=>"", "route_id"=>"68"})
      c.should be_valid
    end
  end

  it "enforce password minimum length requirement" do
    new_customer = Fabricate.build(:customer, password: 'a' * 5)

    new_customer.should_not be_valid
    new_customer.errors.get(:password).should include "is too short (minimum is 6 characters)"
  end

  context 'with a customer' do
    before { @customer = Fabricate(:customer) }

    context 'initializing' do
      specify { @customer.address.should_not be_nil }
      specify { @customer.account.should_not be_nil }
      specify { @customer.number.should_not be_nil }
    end

    describe '#email' do
      before do
        @customer.email = ' BuckyBox@Example.com '
        @customer.save
      end

      specify { @customer.email.should == 'buckybox@example.com' }
    end

    describe '#number' do
      before { @customer.number = -1 }
      specify { @customer.should_not be_valid }
    end

    describe 'a random password is generated if empty' do
      before do
        @customer.password = @customer.password_confirmation = ''
        @customer.save
      end

      specify { @customer.password.should_not be_nil }
      specify { @customer.randomize_password.length == 12 }
      specify { Customer.generate_random_password.should_not == Customer.generate_random_password }
    end

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
      before { @customer.name = 'John Smith' }
      specify { @customer.first_name.should == 'John' }
      specify { @customer.last_name.should == 'Smith' }
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

  describe '.search' do
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

  describe '#new?' do
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
        @o1 = Fabricate(:active_recurring_order, account: customer.account)
        @o2 = Fabricate(:active_recurring_order, account: customer.account)
        @o3 = Fabricate(:active_recurring_order, account: customer.account)
        customer.reload
      end

      specify { customer.order_with_next_delivery.should == @o3 }

      context 'and order without next delivery' do
        before do
          @o4 = Fabricate(:order)
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
      @order = Fabricate(:active_recurring_order, account: customer.account)
      customer.reload
    end

    specify { customer.next_delivery_time.should == @order.schedule_rule.next_occurrence.to_date }
  end

  describe "balance_threshold" do
    context :halt_orders do
      it 'should halt orders' do
        customer = Fabricate(:customer).reload
        account = customer.account
        order = Fabricate(:active_recurring_order, account: account)

        order.next_occurrence.should_not be_blank

        customer.halt!

        order.next_occurrence.should be_blank
      end

      it 'should unhalt orders' do
        customer = Fabricate(:customer).reload
        customer.halt!
        account = customer.account
        order = Fabricate(:active_recurring_order, account: account)
        customer.reload
        order.next_occurrence.should be_blank

        customer.unhalt!
        order.next_occurrence.should_not be_blank
      end
    end

    context :halt_notifications do
      it 'should create a notification for the distributor when halted' do
        customer = Fabricate(:customer).reload
        customer.should_receive(:create_halt_notifications)
        customer.halt!
      end
    end
  end
end
