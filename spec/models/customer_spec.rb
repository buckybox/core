require 'spec_helper'

describe Customer do
  before { @customer = Fabricate(:customer, email: ' BuckyBox@example.com ') }

  specify { @customer.should be_valid }
  specify { @customer.email.should == 'buckybox@example.com' }

  context 'initializing' do
    before(:each) do
      @customer = Customer.create!(first_name: 'test',
                                   last_name: 'test',
                                   email: 'test@buckybox.com',
                                   route: Fabricate(:route),
                                   distributor: Fabricate(:distributor))
    end

    specify { @customer.address.should_not be_nil }
    specify { @customer.account.should_not be_nil }
    specify { @customer.number.should_not be_nil }
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

  context 'when searching' do
    before :each do
      address = Fabricate(:address, city: 'Edinburgh')
      customer2 = address.customer
      customer2.first_name = 'Smith'
      customer2.save

      Fabricate(:address, city: 'Edinburgh')
      Fabricate(:customer, last_name: 'Smith')
      Fabricate(:customer, first_name: 'John', :last_name =>'Smith')
    end

    specify { Customer.search('Edinburgh').size.should == 2 }
    specify { Customer.search('Smith').size.should == 3 }
    specify { Customer.search('John').size.should == 1 }
  end

  context 'when using tags' do
    before :each do
      @customer = Fabricate(:customer)
      @customer.tag_list = 'dog, cat, rain'
      @customer.save
    end

    specify { @customer.tags.size.should == 3 }
    specify { @customer.tag_list.sort.should == %w(cat dog rain) }
  end

  context '.import' do
    let(:customer){ Fabricate.build(:customer) }

    it "should import customer with all fields" do
      route = mock_model(Route)
      boxes = []
      box = box_mock({box_type: "Rural Van"})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("Rural Van").and_return(mock_model('Box'))
      boxes << box

      box = box_mock({box_type: "City Van"})
      customer.stub_chain(:distributor, :boxes, :find_by_name).with("City Van").and_return(mock_model('Box'))
      boxes << box

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
      boxes: 2.times.collect{box_mock}
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
      delivery_frequency: "Weekly",
      delivery_days: "Monday, Tuesday, Friday",
      next_delivery_date: "23-Mar-2013"
          }.merge(opts)
    extras = { 'class'.to_sym => Bucky::Import::Box }
    attrs.merge(extras).each do |key, value|
      box.stub(key).and_return(value)
    end

    box
  end
end
