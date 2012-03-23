require 'spec_helper'

describe Address do
  specify { Fabricate.build(:address).should be_valid }

  context '#join' do
    before { @address = Fabricate.build(:full_address) }

    specify { @address.join.should == '1 Address St, Apartment 1, Suburb, City' }
    specify { @address.join('#').should == '1 Address St#Apartment 1#Suburb#City' }
    specify { @address.join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City, 00000' }
    specify { @address.join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Phone 1: 11-111-111-1111, Phone 2: 22-222-222-2222, Phone 3: 33-333-333-3333' }

    specify { Fabricate.build(:full_address, phone_2: nil).join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Phone 1: 11-111-111-1111, Phone 3: 33-333-333-3333' }
    specify { Fabricate.build(:full_address, postcode: nil).join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City' }
  end
end
