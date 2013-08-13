require 'spec_helper'

describe PhoneCollection do
  context "without any numbers" do
    before do
      @address = double("Address",
        mobile_phone: nil,
        home_phone: nil,
        work_phone: nil,
      )

      @phone_collection = PhoneCollection.new @address
    end

    it "defaults to the first number" do
      expect(@phone_collection.default_number).to eq nil
      expect(@phone_collection.default_type).to eq "mobile"
    end
  end

  context "with a work number" do
    before do
      @address = double("Address",
        mobile_phone: nil,
        home_phone: nil,
        work_phone: "007",
      )

      @phone_collection = PhoneCollection.new @address
    end

    it "defaults to the first present number" do
      expect(@phone_collection.default_number).to eq "007"
      expect(@phone_collection.default_type).to eq "work"
    end
  end
end
