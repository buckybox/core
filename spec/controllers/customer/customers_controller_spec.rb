require 'spec_helper'

describe Customer::CustomersController do
  as_customer

  describe "PUT 'update'" do
    context "with a valid customer" do
      before do
        @customer.should be_valid
      end

      it "updates the customer" do
        put :update, id: @customer.id
        flash[:error].should be_nil
      end
    end

    context "with an invalid customer" do
      before do
        @customer.address.postcode = ""
        @customer.save!

        @customer.distributor.require_postcode = true
        @customer.distributor.save!

        @customer.should_not be_valid
      end

      it "still updates the customer" do
        put :update, id: @customer.id
        flash[:error].should be_nil
      end

      it "does not set non-validated attributes" do
        put :update, { id: @customer.id, address: { postcode: "UNVALIDATED" } }
        @customer.reload.address.postcode.should be_empty
      end
    end
  end
end
