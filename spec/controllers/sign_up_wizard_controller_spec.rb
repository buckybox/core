require 'spec_helper'

describe SignUpWizardController do
  before do
    @nz = Fabricate(:country, alpha2: "NZ")
  end

  describe "#form" do
    before do
      get :form
    end

    it "sets the country" do
      expect(assigns[:country]).to eq "NZ"
    end

    it "sets the time zone" do
      expect(assigns[:time_zone]).to eq "Pacific/Auckland"
    end

    context "rendering views" do
      render_views

      it "doesn't crash when geolocation fails" do
        allow(request).to receive(:remote_ip).and_return "78.157.23.190" # unknown country

        expect { get :form }.not_to raise_error
      end
    end
  end

  describe "#country" do
    before do
      post :country, country: "NZ"
    end

    it "sets the form fields" do
      expect(assigns[:fields]).to include(*%w(street state city zip))
    end
  end

  describe "#sign_up" do
    let(:form_params) do
      {"distributor"=>{"name"=>"My new org", "contact_name"=>"Name", "email"=>"email@example.net", "password"=>"password", "password_confirmation"=>"password", "country"=>"NZ", "time_zone"=>"Auckland", "localised_address_attributes"=>{"street"=>"Street", "state"=>"State", "city"=>"City", "zip"=>"Zip"}, "phone"=>"000", "support_email"=>"support@example.net", "parameter_name"=>"store.buckybox.com/my-new-org", "payment_bank_deposit"=>"1", "bank_name"=>"Kiwibank", "payment_cash_on_delivery"=>"0", "payment_credit_card"=>"1", "payment_direct_debit"=>"0", "payment_bitcoin"=>"0", "source"=>"Word of mouth"}}
    end

    context "with valid params" do
      let(:post_form) do
        lambda { post :sign_up, form_params }
      end

      it "saves the new distributor" do
        expect do
          post_form.call
        end.to change{Distributor.count}.by(1)
      end

      it "saves the new distributor attributes" do
        post_form.call

        distributor = Distributor.where(name: form_params["distributor"]["name"]).last
        expect(distributor.parameter_name).to eq "my-new-org"
        expect(distributor.country).to eq Country.find_by_alpha2("NZ")
        expect(distributor.currency).to eq "NZD"
      end

      it 'adds default line items to distributor' do
        expect do
          post_form.call
        end.to change(LineItem, :count).by(LineItem::DEFAULT_LIST.split(",").size)
      end

      it "returns success response" do
        post_form.call

        expect(response).to be_success
      end

      it "sends the follow up email" do
        expect(AdminMailer).to receive(:information_email) { double(deliver: nil) }

        post_form.call
      end

      it "sends the welcome email" do
        expect(DistributorMailer).to receive(:welcome) { double(deliver: nil) }

        post_form.call
      end

      context "with matching omni importer" do
        before do
          @omni_importer = Fabricate(:omni_importer_for_bank_deposit, country: @nz, bank_name: form_params["distributor"]["bank_name"])
        end

        it "sets up omni importers for the bank" do
          post_form.call

          pending "fails randomly"
          fail
          distributor = Distributor.where(name: form_params["distributor"]["name"]).last
          expect(distributor.omni_importers).to eq [@omni_importer]
        end
      end

      context "when PayPal is selected" do
        let(:form_params_with_paypal) do
          form_params_with_paypal = form_params
          form_params_with_paypal["distributor"]["payment_paypal"] = "1"
          form_params_with_paypal["distributor"]["country"] = "NZ"
          form_params_with_paypal
        end

        before do
          # we assume there is a "generic" PayPal omni with no country in the DB
          @generic_paypal = Fabricate(:paypal_omni_importer, country: nil)
        end

        context "when the selected country has a PayPal omni importer" do
          before do
            @omni_importers = [
              Fabricate(:paypal_omni_importer, country: @nz),
              Fabricate(:omni_importer_for_bank_deposit, country: @nz, bank_name: form_params["distributor"]["bank_name"])
            ]
          end

          it "sets it up for the selected country" do
            post :sign_up, form_params_with_paypal

            pending "fails randomly"
            fail
            distributor = Distributor.where(name: form_params["distributor"]["name"]).last
            expect(distributor.omni_importers).to match_array @omni_importers
          end
        end

        context "when the selected country does not have a PayPal omni importer" do
          let(:form_params_with_paypal_fallback) do
            form_params_with_paypal_fallback = form_params_with_paypal
            form_params_with_paypal_fallback["distributor"]["country"] = "FR"
            form_params_with_paypal_fallback
          end

          it "uses the generic paypal omni" do
            post :sign_up, form_params_with_paypal

            distributor = Distributor.where(name: form_params["distributor"]["name"]).last
            expect(distributor.omni_importers).to match_array [OmniImporter.generic_paypal]
          end
        end
      end

      context "when a new bank is selected" do
        let(:form_params_with_new_bank) do
          form_params_with_new_bank = form_params
          form_params_with_new_bank["distributor"]["bank_name"] = "My new bank"
          form_params_with_new_bank
        end

        it "sends the bank setup email" do
          expect(DistributorMailer).to receive(:bank_setup) { double(deliver: nil) }

          post :sign_up, form_params_with_new_bank
        end
      end
    end

    context "with GB as the country" do
      let(:gb) { Fabricate(:country, alpha2: "GB") }

      let(:gb_form_params) do
        gb_form_params = form_params
        gb_form_params["distributor"]["country"] = gb.alpha2
        gb_form_params
      end

      let(:post_form) do
        lambda { post :sign_up, gb_form_params }
      end

      it "sets it up correctly" do
        post_form.call

        distributor = Distributor.last
        expect(distributor.country.alpha2).to eq "GB"
        expect(distributor.currency).to eq "GBP"
      end
    end

    context "with invalid params" do
      let(:invalid_form_params) do
        invalid_form_params = form_params
        invalid_form_params["distributor"]["localised_address_attributes"]["street"] = ""
        invalid_form_params
      end

      let(:post_form) do
        lambda { post :sign_up, invalid_form_params }
      end

      it "does not create a distributor" do
        expect do
          post_form.call
        end.to_not change{Distributor.count}
      end

      it "returns failure response" do
        post_form.call

        expect(response).not_to be_success
      end

      it "mentions the invalid fields" do
        post_form.call

        expect(response.body).to include "street"
      end
    end

    context "with unknown country" do
      let(:unknown_country_form_params) do
        unknown_country_form_params = form_params
        unknown_country_form_params["distributor"]["country"] = "ZZ"
        unknown_country_form_params
      end

      let(:post_form) do
        lambda { post :sign_up, unknown_country_form_params }
      end

      it "crashes!" do
        expect do
          post_form.call
        end.to raise_error RuntimeError
      end
    end
  end
end
