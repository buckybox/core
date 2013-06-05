require 'spec_helper'

describe Address do
  let(:attrs){ {address_1: "1 Address St", address_2: "Apartment 1", suburb: "Suburb", city: "City"} }
  let(:all_attrs){ attrs.merge({postcode: "00000", mobile_phone: "11-111-111-1111", home_phone: "22-222-222-2222", work_phone: "33-333-333-3333"})}

  describe "#phones" do
    it "returns phone numbers" do
      address = Fabricate(:address, mobile_phone: '005')
      address.mobile_phone.should eq '005'
    end

    it "returns all phone numbers" do
      address = Fabricate(:address, mobile_phone: '005', work_phone: '123')
      address.phones.all.should eq ["Mobile phone: 005", "Work phone: 123"]
    end
  end

  describe "#phone=" do
    it "assigns the number" do
      address = Fabricate.build(:address, phone: {type: 'work', number: '007'})
      address.save!
      address.reload.work_phone.should eq "007"
    end
  end

  describe "#mobile_phone=" do
    it "assigns the number" do
      address = Fabricate.build(:address)
      address.mobile_phone = "009"
      address.save!
      address.reload.mobile_phone.should eq "009"
    end
  end

  describe "#skip_validations" do
    it "skips the given validations" do
      address = Address.new
      address.distributor = mock_model(Distributor)
      address.valid?.should be_false # requires a customer

      valid = address.skip_validations(:customer) { |address| address.valid? }
      valid.should be_true
    end
  end

  describe '#join' do
    let(:address) { Fabricate.build(:address, all_attrs) }
    let(:full_address) { Fabricate.build(:full_address, all_attrs) }

    specify { address.should be_valid }

    specify { full_address.join.should == '1 Address St, Apartment 1, Suburb, City' }
    specify { full_address.join('#').should == '1 Address St#Apartment 1#Suburb#City' }
    specify { full_address.join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City, 00000' }
    specify { full_address.join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Mobile phone: 11-111-111-1111, Home phone: 22-222-222-2222, Work phone: 33-333-333-3333' }

    specify { Fabricate.build(:full_address, all_attrs.merge(home_phone: nil)).join(', ', with_phone: true).should == '1 Address St, Apartment 1, Suburb, City, Mobile phone: 11-111-111-1111, Work phone: 33-333-333-3333' }
    specify { Fabricate.build(:full_address, all_attrs.merge(postcode: nil)).join(', ', with_postcode: true).should == '1 Address St, Apartment 1, Suburb, City' }
  end

  describe '.==' do
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
