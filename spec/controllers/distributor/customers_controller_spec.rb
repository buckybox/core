require 'spec_helper'

describe Distributor::CustomersController do
  render_views

  as_distributor
  context :with_customer do
    before { @customer = Fabricate(:customer, distributor: @distributor) }

    context "send_login_details" do
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
        assigns(:customer).password.should_not == @customer.password
      end

      it "should redirect correctly" do
        response.should redirect_to(distributor_customer_path(@customer))
      end
    end

    context "#update" do
      before do
        @customer_2 = Fabricate(:customer, distributor: @distributor, email: "duplicate@dups.com")
      end

      it 'should show the errors' do
        put :update, id: @customer.id, customer: {email: "duplicate@dups.com"}
        assigns(:form_type).should eq('personal_form')
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

          response.should be_successful
          message.should eq "Your changes have been saved."
        end
      end

      context "deleting" do
        before do
          @distributor.update_attributes(email_templates: email_templates)
        end

        it "deletes the template" do
          post :email, params.merge(link_action: "delete")

          response.should be_successful
          message.should eq "Email template <em>#{email_templates[1].subject}</em> has been deleted."
        end
      end

      context "saving" do
        it "saves the template" do
          post :email, params.merge(link_action: "save")

          response.should be_successful
          message.should eq "Your new email template <em>#{email_template["subject"]}</em> has been saved."
        end
      end

      context "previewing" do
        it "sends a preview email" do
          CustomerMailer.should_receive(:email_template) do |recipient, email|
            recipient.should eq @distributor
            email.subject.should eq email_template["subject"]
          end.and_call_original

          post :email, params.merge(link_action: "preview")

          response.should be_successful
          message.should eq "A preview email has been sent to #{@distributor.email}."
        end
      end

      context "sending" do
        before do
          @post = lambda { post :email, params.merge(commit: "", link_action: "") }
        end

        it "calls send_email with the right arguments" do
          controller.should_receive(:send_email) do |ids, email|
            ids.should eq recipient_ids
            email.subject.should eq email_template["subject"]
          end

          @post.call
        end

        it "sets the flash message" do
          @post.call

          flash[:notice].should_not be_nil
        end

        it "sends emails" do
          mock_delay = double('mock_delay').as_null_object
          CustomerMailer.stub(:delay).and_return(mock_delay)
          mock_delay.should_receive(:email_template)

          @post.call
        end
      end
    end
  end
end
