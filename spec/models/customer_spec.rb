require 'spec_helper'

describe Customer do
  def customer_mock(opts = {})
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
      delivery_service: "Rural Van",
      delivery_address_line_1: 'camp site 2c',
      delivery_address_line_2: 'next to the toilet',
      delivery_suburb: 'Solway',
      delivery_city: 'Masterton',
      delivery_postcode: '1234567',
      delivery_instructions: 'by the zips please',
      mobile_phone: '0800 999 666 333',
      home_phone: '0800 BOWIES IN SPACE',
      tags: ["Flight of the concords", "rock"],
      boxes: 2.times.collect { box_mock },
    }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Customer }
    attrs.merge(extras).each do |key, value|
      allow(customer).to receive(key).and_return(value)
    end

    customer
  end

  def box_mock(opts = {})
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
      extras: 2.times.collect { extra_mock }
          }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Box }
    attrs.merge(extras).each do |key, value|
      allow(box).to receive(key).and_return(value)
    end

    box
  end

  def extra_mock(opts = {})
    extra = double("Bucky::Import::Extra")
    attrs = {
      count: 1,
      name: "Bacon",
      unit: "7 slices"
          }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Extra }
    attrs.merge(extras).each do |key, value|
      allow(extra).to receive(key).and_return(value)
    end

    extra
  end

  let(:customer) { Fabricate(:customer) }

  specify { expect(customer).to be_valid }

  context :create_with_account_under_limit do
    let(:distributor) { Fabricate(:distributor, default_balance_threshold_cents: -50_000, has_balance_threshold: true) }

    it 'should create a valid customer' do
      c = distributor.customers.create({ "first_name" => "Jordan", "last_name" => "Carter", "tag_list" => "", "email" => "jordan+3@buckybox.com", "address_attributes" => { "mobile_phone" => "", "home_phone" => "", "work_phone" => "", "address_1" => "43a Warwick St", "address_2" => "Wilton", "suburb" => "Wellington", "city" => "Wellington", "postcode" => "6012", "delivery_note" => "" }, "balance_threshold" => "1.00", "discount" => "0", "special_order_preference" => "", "delivery_service_id" => "68" })
      expect(c).to be_valid
    end
  end

  it "enforces password minimum length requirement" do
    new_customer = Fabricate.build(:customer, password: 'a' * 5)

    expect(new_customer).not_to be_valid
    expect(new_customer.errors.get(:password)).to include "is too short (minimum is 6 characters)"
  end

  context "when a customer is created" do
    it "does not send their login details" do
      expect(CustomerMailer).not_to receive(:login_details)
      Fabricate(:customer)
    end
  end

  context "when a customer is created via the webstore" do
    it "does send their login details" do
      expect(CustomerMailer).to receive(:login_details).and_call_original
      Fabricate(:customer, via_webstore: true)
    end
  end

  context 'with a customer' do
    before { @customer = Fabricate(:customer) }

    context 'initializing' do
      specify { expect(@customer.address).not_to be_nil }
      specify { expect(@customer.account).not_to be_nil }
      specify { expect(@customer.number).not_to be_nil }
    end

    describe "#dynamic_tags" do
      specify { expect(@customer.dynamic_tags).to be_a Hash }

      context "with a negative balance" do
        before { allow(@customer).to receive(:account_balance) { CrazyMoney.new(-1) } }

        specify { expect(@customer.dynamic_tags).to have_key "negative-balance" }
      end

      context "with a positive balance" do
        before { allow(@customer).to receive(:account_balance) { CrazyMoney.new(1) } }

        specify { expect(@customer.dynamic_tags).to_not have_key "negative-balance" }
      end
    end

    describe '#email' do
      before do
        @customer.email = ' BuckyBox@Example.com '
        @customer.save
      end

      specify { expect(@customer.email).to eq 'buckybox@example.com' }
    end

    describe "#email_to" do
      it "returns the expected recipient" do
        customer = Fabricate.build(:customer,
          first_name: "Will",
          last_name: "Lau",
          email: "will@example.net"
        )

        expect(customer.email_to).to eq "Will Lau <will@example.net>"
      end
    end

    describe '#number' do
      before { @customer.number = -1 }
      specify { expect(@customer).not_to be_valid }

      it "enforces uniqueness per distributor at the DB level" do
        customer_1 = Fabricate(:customer)
        customer_2 = Fabricate(:customer, distributor: customer_1.distributor)

        customer_2.number = customer_1.number

        expect do
          customer_2.save(validate: false)
        end.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    describe 'a random password is generated if empty' do
      before do
        @customer.password = @customer.password_confirmation = ''
        @customer.save
      end

      specify { expect(@customer.password).not_to be_nil }
    end

    describe '#name' do
      describe 'with only first name' do
        specify { expect(@customer.name).to eq @customer.first_name }
      end

      describe 'with both first and last name' do
        before { @customer.last_name = 'Lastname' }
        specify { expect(@customer.name).to eq "#{@customer.first_name} #{@customer.last_name}" }
      end
    end

    describe '#name=' do
      before { @customer.name = 'John Smith' }
      specify { expect(@customer.first_name).to eq 'John' }
      specify { expect(@customer.last_name).to eq 'Smith' }
    end

    context 'when using tags' do
      before :each do
        @customer.tag_list = 'dog, cat, rain'
        @customer.save
      end

      specify { expect(@customer.tags.size).to eq 3 }
      specify { expect(@customer.tag_list.sort).to eq %w(cat dog rain) }
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

    specify { expect(Customer.search('Edinburgh').size).to eq 2 }
    specify { expect(Customer.search('Smith').size).to eq 3 }
    specify { expect(Customer.search('John').size).to eq 1 }
  end

  describe '#new?' do
    before { @customer = Fabricate(:customer) }

    context 'customer has 0 deliveries' do
      before { allow(@customer.deliveries).to receive(:size).and_return(0) }
      specify { expect(@customer.new?).to be true }
    end

    context 'customer has 1 delivery' do
      before { allow(@customer.deliveries).to receive(:size).and_return(1) }
      specify { expect(@customer.new?).to be true }
    end

    context 'customer has 2 deliveries' do
      before { allow(@customer.deliveries).to receive(:size).and_return(2) }
      specify { expect(@customer.new?).to be false }
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

      specify { expect(customer.order_with_next_delivery).to eq @o3 }

      context 'and order without next delivery' do
        before do
          @o4 = Fabricate(:order)
          @o4.stub_chain(:schedule, :next_occurrence).and_return(nil)
          customer.stub_chain(:account, :active_orders).and_return([@o1, @o2, @o3])
        end

        specify { expect(customer.order_with_next_delivery).to eq @o3 }
      end
    end

    context 'without orders' do
      before { customer.stub_chain(:account, :active_orders).and_return([]) }
      specify { expect(customer.order_with_next_delivery).to eq nil }
    end
  end

  describe '#next_delivery_time' do
    before do
      @order = Fabricate(:active_recurring_order, account: customer.account)
      customer.reload
    end

    specify { expect(customer.next_delivery_time).to eq @order.schedule_rule.next_occurrence.to_date }
  end

  describe "balance_threshold" do
    context :halt_orders do
      it 'should halt orders' do
        customer = Fabricate(:customer).reload
        account = customer.account
        order = Fabricate(:active_recurring_order, account: account)

        expect(order.next_occurrence).not_to be_blank

        customer.halt!

        expect(order.next_occurrence).to be_blank
      end

      it 'should unhalt orders' do
        customer = Fabricate(:customer).reload
        customer.halt!
        account = customer.account
        order = Fabricate(:active_recurring_order, account: account)
        customer.reload
        expect(order.next_occurrence).to be_blank

        customer.unhalt!
        expect(order.next_occurrence).not_to be_blank
      end
    end

    context :halt_notifications do
      it 'should create a notification for the distributor when halted' do
        customer = Fabricate(:customer).reload
        expect(customer).to receive(:create_halt_notifications)
        customer.halt!
      end
    end
  end

  describe ".last_paid" do
    it "returns the last payment transaction date" do
      distributor = customer.distributor
      Fabricate(:payment, display_time: 1.weeks.ago, account: customer.account, amount_cents: 100, distributor: distributor)
      p = Fabricate(:payment, display_time: 1.day.ago, account: customer.account, amount_cents: 100, distributor: distributor)
      Fabricate(:payment, display_time: 3.days.ago, account: customer.account, amount_cents: -100, distributor: distributor)
      Fabricate(:payment, display_time: 2.weeks.ago, account: customer.account, amount_cents: 100, distributor: distributor)
      p.reverse_payment!

      expect(customer.last_paid.to_date).to eq 1.weeks.ago.to_date
    end

    it "returns nil when no payments" do
      expect(customer.last_paid).to be_nil
    end

    it "includes COD payments" do
      delivery = Fabricate(:delivery)
      allow(delivery).to receive(:account).and_return(customer.account)
      allow(delivery).to receive(:distributor).and_return(customer.distributor)
      Delivery.pay_on_delivery([delivery])
      expect(customer.last_paid).not_to be_nil
    end
  end

  describe 'customer activity' do
    let(:customer) { Fabricate.build(:customer) }

    describe '#active?' do
      it 'with active orders returns true' do
        stub_active_orders(customer, [double('orders')])
        expect(customer.active?).to be true
      end

      it 'without active orders returns false' do
        stub_active_orders(customer, [])
        expect(customer.active?).to be false
      end
    end

    describe '#active_orders' do
      it 'returns the customers orders that are active' do
        orders = [double('orders')]
        stub_active_orders(customer, orders)
        expect(customer.active_orders).to eq(orders)
      end
    end

    def stub_active_orders(customer, orders)
      scoped = double('scoped', active: orders)
      allow(customer).to receive(:orders) { scoped }
    end
  end
end
