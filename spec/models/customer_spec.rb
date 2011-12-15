require 'spec_helper'

describe Customer do
  before :all do
    @customer = Fabricate(:customer)
  end

  specify { @customer.should be_valid }

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
end
