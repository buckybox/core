require 'spec_helper'

describe Customer::CustomersController do
  as_customer

  describe "PUT 'udpate_password'" do
    context "with a valid password" do
      it "updates the password" do
        pass = 'a' * 6
        put :update_password, id: @customer.id, customer: { password: pass, password_confirmation: pass }
        flash[:error].should be_nil
      end
    end

    context "with a password too short" do
      it "fails" do
        pass = 'a' * 5
        put :update_password, id: @customer.id, customer: { password: pass, password_confirmation: pass }
        flash[:error].should_not be_nil
      end
    end
  end
end

