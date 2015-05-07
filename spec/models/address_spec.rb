require 'spec_helper'

describe Address do
  let(:attrs) { { address_1: "1 Address St", address_2: "Apartment 1", suburb: "Suburb", city: "City" } }
  let(:all_attrs) { attrs.merge({ postcode: "00000", mobile_phone: "11-111-111-1111", home_phone: "22-222-222-2222", work_phone: "33-333-333-3333" }) }

  describe "#phones" do
    it "returns phone numbers" do
      address = Fabricate(:address, mobile_phone: '005')
      expect(address.mobile_phone).to eq '005'
    end

    it "returns all phone numbers" do
      address = Fabricate(:address, mobile_phone: '005', work_phone: '123')
      expect(address.phones.all).to eq ["Mobile phone: 005", "Work phone: 123"]
    end
  end

  describe "#phone=" do
    it "assigns the number" do
      address = Fabricate.build(:address, phone: { type: 'work', number: '007' })
      address.save!
      expect(address.reload.work_phone).to eq "007"
    end
  end

  describe "#mobile_phone=" do
    it "assigns the number" do
      address = Fabricate.build(:address)
      address.mobile_phone = "009"
      address.save!
      expect(address.reload.mobile_phone).to eq "009"
    end
  end

  describe '#join' do
    let(:address) { Fabricate.build(:address, all_attrs) }
    let(:full_address) { Fabricate.build(:full_address, all_attrs) }

    specify { expect(address).to be_valid }

    specify { expect(full_address.join).to eq '1 Address St, Apartment 1, Suburb, City, 00000' }
    specify { expect(full_address.join('#')).to eq '1 Address St#Apartment 1#Suburb#City#00000' }
    specify { expect(full_address.join(', ')).to eq '1 Address St, Apartment 1, Suburb, City, 00000' }
    specify { expect(full_address.join(', ', with_phone: true)).to eq '1 Address St, Apartment 1, Suburb, City, 00000, Mobile phone: 11-111-111-1111, Home phone: 22-222-222-2222, Work phone: 33-333-333-3333' }

    specify { expect(Fabricate.build(:full_address, all_attrs.merge(home_phone: nil)).join(', ', with_phone: true)).to eq '1 Address St, Apartment 1, Suburb, City, 00000, Mobile phone: 11-111-111-1111, Work phone: 33-333-333-3333' }
  end

  describe '.==' do
    let(:address) { Fabricate.build(:address, attrs) }

    it 'should return true for matching address' do
      expect(address).to eq Fabricate.build(:address, attrs)
    end

    it 'should return false for different addresses' do
      attrs.each do |key, _value|
        expect(address).not_to eq(Fabricate.build(:address, attrs.merge(key => "Something different")))
      end
    end

    it 'should return the same hash for the same address' do
      expect(address.address_hash).to eq Fabricate.build(:address, attrs).address_hash
    end

    it 'should return a unique hash for unique addresses' do
      attrs.each do |key, _value|
        expect(address.address_hash).not_to eq(Fabricate.build(:address, attrs.merge(key => "Something else")).address_hash)
      end
    end
  end
end
