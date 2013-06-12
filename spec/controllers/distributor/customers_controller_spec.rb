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
      let(:email_templates) {
        {"0" => {
            "subject" => "Hey!",
            "body" => "Hi [first_name],\r\n\r\nCheers"
          },
         "1" => {"subject" => "", "body" => ""}
        }
      }

      before do
        @post = lambda { post :email,
          recipient_ids: recipient_ids.join(','),
          selected_email_template_id: "0",
          email_templates: email_templates
        }
      end

      it "calls send_email with the right arguments" do
        controller.should_receive(:send_email) do |ids, email|
          ids.should eq recipient_ids
          email.should be_a EmailTemplate
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
