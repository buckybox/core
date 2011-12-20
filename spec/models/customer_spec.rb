require 'spec_helper'

describe Customer do
  before :all do
    @customer = Fabricate(:customer)
  end

  specify { @customer.should be_valid }

  context "initializing" do
    it "creates a customer number" do
      @customer.number.should_not be_nil
    end
    it "throws error if unable to find a free customer number" do
      distributor = Fabricate(:distributor)
      distributor.stub_chain(:customers,:find_by_number).and_return(true)
      lambda{
        Fabricate(:customer, :distributor => distributor)
      }.should raise_error 
    end
    it "creates an account" do
      @customer.account.should_not be_nil
    end
  end

  context 'full name' do
    describe '#name' do
      specify { @customer.name.should == "#{@customer.first_name} #{@customer.last_name}" }
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
end
