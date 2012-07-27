require 'spec_helper'

describe Address do
  let(:attrs){ {address_1: "1 Address St", address_2: "Apartment 1", suburb: "Suburb", city: "City"} }
  let(:all_attrs){ attrs.merge({postcode: "00000", phone_1: "11-111-111-1111", phone_2: "22-222-222-2222", phone_3: "33-333-333-3333"})}

  context '#join' do
    let(:address) { Fabricate.build(:address, all_attrs) }
    let(:full_address) { Fabricate.build(:full_address, all_attrs) }

    specify { address.should be_valid }

    specify { full_address.join.should == '1 Address St, Apartment 1, Suburb, City' }
    specify { full_address.join('#').should == '1 Address St#Apartment 1#Suburb#City' }
    specify { full_address.join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City, 00000' }
    specify { full_address.join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Phone 1: 11-111-111-1111, Phone 2: 22-222-222-2222, Phone 3: 33-333-333-3333' }

    specify { Fabricate.build(:full_address, all_attrs.merge(phone_2: nil)).join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Phone 1: 11-111-111-1111, Phone 3: 33-333-333-3333' }
    specify { Fabricate.build(:full_address, all_attrs.merge(postcode: nil)).join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City' }
  end

  context '.==' do
    let(:address){ Fabricate.build(:address, attrs)}

    it 'should return true for matching address' do
      address.should == Fabricate.build(:address, attrs)
    end

    it 'should return false for different addresses' do
      attrs.each do |key, value|
        address.should_not eq(Fabricate.build(:address, attrs.merge(key => "Something different")))
      end
    end

    it 'should return the same hash for the same address' do
      address.address_hash.should == Fabricate.build(:address, attrs).address_hash
    end

    it 'should return a unique hash for unique addresses' do
      attrs.each do |key, value|
        address.address_hash.should_not eq(Fabricate.build(:address, attrs.merge(key => "Something else")).address_hash)
      end
    end
  end
end
