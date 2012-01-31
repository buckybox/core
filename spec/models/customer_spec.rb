require 'spec_helper'

describe Customer do
  before :all do
    @customer = Fabricate(:customer, :email => ' BuckyBox@example.com ')
  end

  specify { @customer.should be_valid }
  specify { @customer.email.should == 'buckybox@example.com' }

  context "initializing" do
    before(:each) do
      @customer = Customer.create!(:first_name => 'test', 
                               :last_name => 'test',
                               :email => 'test@buckybox.com',
                               :route => Fabricate(:route),
                               :distributor => Fabricate(:distributor))
    end

    specify { @customer.number.should_not be_nil }
    specify { @customer.account.should_not be_nil }

    it "creates a customer number" do
      @customer.number.should_not be_nil
    end
    it "throws error if unable to find a free customer number" do
      distributor = Fabricate(:distributor)
      distributor.stub_chain(:customers,:find_by_number).and_return(true)

      expect {  Fabricate(:customer, :distributor => distributor) }.should raise_error 
    end
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
      address = Fabricate(:address, :city => 'Edinburgh')
      customer2 = address.customer
      customer2.first_name = 'Smith'
      customer2.save

      Fabricate(:address, :city => 'Edinburgh')
      Fabricate(:customer, :last_name => 'Smith')
      Fabricate(:customer, :first_name => 'John', :last_name =>'Smith')
    end

    specify { Customer.search('Edinburgh').size.should == 2 }
    specify { Customer.search('Smith').size.should == 3 }
    specify { Customer.search('John').size.should == 1 }
  end

  context 'when using tags' do
    before :each do
      @customer.tag_list = 'dog, cat, rain'
      @customer.save
    end

    specify { @customer.tags.size.should == 3 }
    specify { @customer.tag_list.should == %w(dog cat rain) }
  end
end
