require 'spec_helper'

describe Customer::AddressesController do
  sign_in_as_customer

  describe "PUT 'update'" do
    context "with a valid customer" do
      before do
        @customer = Fabricate(:customer)
        @customer.should be_valid
      end

      it "updates the customer address" do
        put :update, id: @customer.id
        flash[:error].should be_nil
      end
    end

    context "with an incomplete customer" do
      before do
        # reset all phone numbers
        PhoneCollection.attributes.each do |phone_type|
          @customer.address.instance_variable_set("@#{phone_type}", "")
        end
        @customer.save!

        @customer.distributor.require_phone = true
        @customer.distributor.save!
      end

      it "still updates the customer address" do
        put :update, id: @customer.id
        flash[:error].should be_nil
      end
    end
  end
end

