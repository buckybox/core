require 'spec_helper'

describe SignUpWizardController do
  before do
    Fabricate(:country, alpha2: "NZ")
  end

  describe "#form" do
    before do
      get :form
    end

    it "sets the country" do
      assigns[:country].should eq "NZ"
    end

    it "sets the time zone" do
      assigns[:time_zone].should eq "Pacific/Auckland"
    end
  end

  describe "#country" do
    before do
      post :country, country: "NZ"
    end

    it "sets the form fields" do
      assigns[:fields].should include(*%w(street state city zip))
    end
  end

  describe "#sign_up" do
    let(:form_params) do
      {"distributor"=>{"name"=>"My new org", "contact_name"=>"Name", "email"=>"email@example.net", "password"=>"password", "password_confirmation"=>"password", "country"=>"NZ", "time_zone"=>"Auckland", "localised_address_attributes"=>{"street"=>"Street", "state"=>"State", "city"=>"City", "zip"=>"Zip"}, "phone"=>"000", "support_email"=>"support@example.net", "parameter_name"=>"my.buckybox.com/webstore/my-new-org", "payment_bank_deposit"=>"1", "bank_name"=>"Kiwibank", "payment_cash_on_delivery"=>"0", "payment_credit_card"=>"1", "payment_direct_debit"=>"0", "source"=>"Word of mouth"}}
    end

    context "with valid params" do
      let(:post_form) do
        lambda { post :sign_up, form_params }
      end

      it "saves the new distributor" do
        expect {
          post_form.call
        }.to change{Distributor.count}.by(1)
      end

      it "saves the new distributor attributes" do
        post_form.call

        distributor = Distributor.where(name: form_params["distributor"]["name"]).last
        distributor.parameter_name.should eq "my-new-org"
        distributor.country.should eq Country.find_by_alpha2("NZ")
      end

      it "returns success response" do
        post_form.call

        response.should be_success
      end

      it "sends the follow up email" do
        AdminMailer.should_receive(:information_email) { double(deliver: nil) }

        post_form.call
      end

      it "sends the welcome email" do
        DistributorMailer.should_receive(:welcome) { double(deliver: nil) }

        post_form.call
      end
    end

    context "with invalid params" do
      let(:invalid_form_params) do
        invalid_form_params = form_params
        invalid_form_params["distributor"]["localised_address_attributes"]["street"] = ""
        invalid_form_params["distributor"]["localised_address_attributes"]["city"] = ""
        invalid_form_params
      end

      let(:post_form) do
        lambda { post :sign_up, invalid_form_params }
      end

      it "does not create a distributor" do
        expect {
          post_form.call
        }.to_not change{Distributor.count}
      end

      it "returns failure response" do
        post_form.call

        response.should_not be_success
      end

      it "mentions the invalid fields" do
        post_form.call

        response.body.should include "street", "city"
      end
    end
  end
end
