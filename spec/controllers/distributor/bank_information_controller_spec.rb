require 'spec_helper'

describe Distributor::BankInformationController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          bank_information: {
            name: 'bnz', account_name: 'company account', account_number: '1', customer_message: 'pay', bsb_number: '1'
          }
        }
      end

      specify { flash[:notice].should eq('Payments information was successfully created.') }
      specify { assigns(:bank_information).account_name.should eq('company account') }
      specify { response.should redirect_to(distributor_settings_bank_information_url) }
    end

    context 'with invalid params' do
      before { post :create, { bank_information: { account_name: '' } } }

      specify { assigns(:bank_information).account_name.should eq('') }
      specify { response.should render_template('distributor/settings/bank_information') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_information: { account_name: 'company account' } }
      end

      specify { flash[:notice].should eq('Payments information was successfully updated.') }
      specify { assigns(:bank_information).account_name.should eq('company account') }
      specify { response.should redirect_to(distributor_settings_bank_information_url) }
    end

    context 'with invalid params' do
      before do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_information: { account_name: '' } }
      end

      specify { assigns(:bank_information).account_name.should eq('') }
      specify { response.should render_template('distributor/settings/bank_information') }
    end
  end
end

