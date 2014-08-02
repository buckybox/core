require 'spec_helper'

describe Distributor::CustomersController do
  render_views

  sign_in_as_distributor

  context "with a customer" do
    before { @customer = Fabricate(:customer, distributor: @distributor) }

    describe "#index" do
      before { allow(controller).to receive(:check_setup) }

      context "with no customers" do
        before { get :index, query: "query_with_no_results" }
        specify { expect(response).to be_success }
      end

      context "with customers" do
        before { get :index }
        specify { expect(response).to be_success }
      end
    end

    describe "#send_login_details" do
      before do
        @send_login_details = lambda { get :send_login_details, id: @customer.id }
        @send_login_details.call
      end

      it "should send an email" do
        expect {
          @send_login_details.call
        }.to change{ActionMailer::Base.deliveries.size}.by(1)
      end

      it "should reset password" do
        expect(assigns(:customer).password).not_to eq @customer.password
      end

      it "should redirect correctly" do
        expect(response).to redirect_to(distributor_customer_path(@customer))
      end
    end

    describe "#show" do
      before do
        Fabricate(:order, account: @customer.account(true))
        @customer.reload
      end

      it "should show the customer and their orders" do
        get :show, id: @customer.id
      end
    end

    describe "#email" do
      let(:recipient_ids) { [@customer.id] }
      let(:email_template) {
        {
          "subject" => "Hey!",
          "body" => "Hi [first_name],\r\n\r\nCheers"
        }
      }
      let(:params) {
        {
          recipient_ids: recipient_ids.join(','),
          selected_email_template_id: "1",
          email_template: email_template,
          link_action: ""
        }
      }

      let(:email_templates) {
        [
          Fabricate(:email_template),
          Fabricate(:email_template)
        ]
      }

      def message
        JSON.parse(response.body)["message"]
      end

      context "updating" do
        before do
          @distributor.update_attributes(email_templates: email_templates)
        end

        it "updates the template" do
          post :email, params.merge(link_action: "update")

          expect(response).to be_successful
          expect(message).to eq "Your changes have been saved."
        end
      end

      context "deleting" do
        before do
          @distributor.update_attributes(email_templates: email_templates)
        end

        it "deletes the template" do
          post :email, params.merge(link_action: "delete")

          expect(response).to be_successful
          expect(message).to eq "Email template <em>#{email_templates[1].subject}</em> has been deleted."
        end
      end

      context "saving" do
        it "saves the template" do
          post :email, params.merge(link_action: "save")

          expect(response).to be_successful
          expect(message).to eq "Your new email template <em>#{email_template["subject"]}</em> has been saved."
        end
      end

      context "previewing" do
        it "sends a preview email" do
          expect(CustomerMailer).to receive(:email_template) { |recipient, email|
            expect(recipient).to eq @distributor
            expect(email.subject).to eq email_template["subject"]
          }.and_call_original

          post :email, params.merge(link_action: "preview")

          expect(response).to be_successful
          expect(message).to eq "A preview email has been sent to #{@distributor.email}."
        end
      end

      context "sending" do
        before do
          @post = lambda { post :email, params.merge(commit: "", link_action: "") }
        end

        it "calls send_email with the right arguments" do
          expect(controller).to receive(:send_email) do |ids, email|
            expect(ids).to eq recipient_ids
            expect(email.subject).to eq email_template["subject"]
          end

          @post.call
        end

        it "sets the flash message" do
          @post.call

          expect(flash[:notice]).not_to be_nil
        end

        it "sends emails" do
          mock_delay = double('mock_delay').as_null_object
          allow(CustomerMailer).to receive(:delay).and_return(mock_delay)
          expect(mock_delay).to receive(:email_template)

          @post.call
        end
      end
    end

    describe "#export" do
      let(:recipient_ids) { [@customer.id] }

      before do
        @post = lambda { post :export, export: {recipient_ids: recipient_ids.join(',') }}
      end

      it "downloads a csv" do
        allow(CustomerCSV).to receive(:generate).and_return("")
        @post.call
        expect(response.headers['Content-Type']).to eq "text/csv; charset=utf-8; header=present"
      end

      it "exports customer data into csv" do
        allow(CustomerCSV).to receive(:generate).and_return("I am the kind of csvs")
        @post.call
        expect(response.body).to eq "I am the kind of csvs"
      end

      it "calls CustomerCSV.generate" do
        allow(CustomerCSV).to receive(:generate)
        expect(CustomerCSV).to receive(:generate).with(@distributor, [@customer.id])
        @post.call
      end
    end
  end
end
