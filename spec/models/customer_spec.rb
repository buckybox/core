require 'spec_helper'

describe Customer do
  let(:customer) { Fabricate(:customer) }

  specify { customer.should be_valid }

  context :create_with_account_under_limit do
    let(:distributor) { Fabricate(:distributor, default_balance_threshold_cents: -50000, has_balance_threshold: true) }

    it 'should create a valid customer' do
      c = distributor.customers.create({"first_name"=>"Jordan", "last_name"=>"Carter", "tag_list"=>"", "email"=>"jordan+3@buckybox.com", "address_attributes"=>{"phone_1"=>"", "phone_2"=>"", "phone_3"=>"", "address_1"=>"43a Warwick St", "address_2"=>"Wilton", "suburb"=>"Wellington", "city"=>"Wellington", "postcode"=>"6012", "delivery_note"=>""}, "balance_threshold"=>"1.00", "discount"=>"0", "special_order_preference"=>"", "route_id"=>"68"})
      c.should be_valid
    end
  end

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
      specify { Customer.generate_random_password.should_not == Customer.generate_random_password }
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

  describe '.import' do
    let(:customer){ Fabricate(:customer) }

    it "should import customer with all fields" do
      route = mock_model(Route)
      route.stub(:includes?).and_return(true)

      boxes = []
      box = box_mock({box_type: "Rural Van", extras_unlimited?: true})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("Rural Van").and_return(mock_model('Box', extras_unlimited?: true, substitutions_limit: 0, exclusions_limit: 0))
      boxes << box

      box = box_mock({box_type: "City Van", extras_unlimited?: true})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("City Van").and_return(mock_model('Box', extras_unlimited?: true, substitutions_limit: 0, exclusions_limit: 0))
      boxes << box

      Distributor.any_instance.stub(:find_extra_from_import).and_return(mock_model('Extra'))
      customer.stub(:default_balance_threshold_cents).and_return(-100000)
      customer.stub(:has_balance_threshold).and_return(false)
      customer.stub(:currency).and_return('NZD')

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

  describe "balance_threshold" do
    it 'should set balance threshold from distributor' do
      distributor = Fabricate(:distributor, default_balance_threshold_cents: 20000)

      customer = Fabricate(:customer, distributor: distributor).reload

      customer.balance_threshold.should eq(200)
    end

    context :changing_balance do
      before do
        customer = Fabricate(:customer, balance_threshold_cents: -20000)
        customer.reload
        distributor = customer.distributor
        distributor.has_balance_threshold = true
        distributor.save!

        customer.balance_threshold_cents = -20000
        customer.save!

        customer.status_halted.should be_false
        customer.balance_threshold.should eq(-200)

        account = customer.account
        @customer = customer
        @account = account
      end

      it 'should put customer into a halt state if they exceed balance threshold' do
        @account.change_balance_to(-200.00)
        @account.save!

        @customer.reload.halted?.should be_true
      end

      it 'should take customer out of halt state when balance goes below threshold' do
        @account.change_balance_to(-200.00)
        @account.save!
        @customer.reload.halted?.should be_true
        @account.reload

        @account.change_balance_to(-199.99)
        @account.save!

        @customer.reload.halted?.should be_false
      end
    end
    
    context :changing_threshold do
      before do
        customer = Fabricate(:customer)
        customer.reload
        account = customer.account

        distributor = customer.distributor
        distributor.has_balance_threshold = true
        distributor.save!

        customer.balance_threshold_cents = -20000
        customer.save!

        @account = account
        @customer = customer
        @distributor = distributor
      end

      it 'should put customer into halt state when threshold lowered' do
        @account.change_balance_to(-100)
        @account.save!
        @customer.reload
        @customer.halted?.should be_false

        @customer.balance_threshold_cents = -5000
        @customer.save!

        @customer.reload.halted?.should be_true
      end

      it 'should take customer out of halt state when threshold raised' do
        @account.change_balance_to(-300)
        @account.save!

        @customer.reload
        @customer.halted?.should be_true

        @customer.balance_threshold_cents = -50000
        @customer.save!

        @customer.reload.halted?.should be_false
      end

      it 'should take customer out of halt when threshold turned off' do
        @account.change_balance_to(-300)
        @account.save!

        @customer.reload
        @customer.halted?.should be_true
        @distributor.reload
        
        @distributor.has_balance_threshold = false
        @distributor.save!

        @customer.reload.halted?.should be_false
      end
      
      it 'should put customer into halt when threshold turned on' do
        @distributor.has_balance_threshold = false
        @distributor.save!
        @account.change_balance_to(-300)
        @account.save!
        @customer.reload
        @customer.halted?.should be_false
        @distributor.reload
        
        @distributor.has_balance_threshold = true
        @distributor.save!
        
        @customer.reload.halted?.should be_true
      end

      it 'should take customer out of halt state when override threshold raised' do
        @account.change_balance_to(-300)
        @account.save!

        @customer.reload
        @customer.halted?.should be_true
        @distributor.reload

        @customer.balance_threshold_cents = -50000
        @customer.save!

        @customer.reload.halted?.should be_false
      end

      it 'should put customer into halt state when override threshold lowered' do
        @account.change_balance_to(-100)
        @account.save!

        @customer.reload
        @customer.halted?.should be_false
        @distributor.reload

        @customer.balance_threshold_cents = -5000
        @customer.save!

        @customer.reload.halted?.should be_true
      end
    end

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
