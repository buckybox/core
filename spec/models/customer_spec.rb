require 'spec_helper'

describe Customer do
  specify { Fabricate.build(:customer).should be_valid }

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
      address = Fabricate(:address, city: 'Edinburgh')
      customer2 = address.customer
      customer2.first_name = 'Smith'
      customer2.save

      Fabricate(:address, city: 'Edinburgh')
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
end
