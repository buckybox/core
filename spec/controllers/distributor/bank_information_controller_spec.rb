require 'spec_helper'

describe Distributor::BankInformationController do
  render_views

  as_distributor
  before { @customer = Fabricate(:customer, :distributor => @distributor) }

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          bank_information: {
            name: 'bnz', account_name: 'company account', account_number: '1', customer_message: 'pay'
          }
        }
      end

      specify { flash[:notice].should eq('Bank information was successfully created.') }
      specify { assigns(:bank_information).account_name.should eq('company account') }
      specify { response.should redirect_to(distributor_settings_bank_information_url) }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { bank_information: { account_name: '' } }
      end

      specify { assigns(:bank_information).errors[:account_name].size.should eq(1)}
      specify { assigns(:bank_information).account_name.should eq('') }
      specify { response.should render_template('distributor/settings/bank_information') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_information: { account_name: 'company account' } }
      end

      specify { flash[:notice].should eq('Bank information was successfully updated.') }
      specify { assigns(:bank_information).account_name.should eq('company account') }
      specify { response.should redirect_to(distributor_settings_bank_information_url) }
    end

    context 'with invalid params' do
      before(:each) do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_information: { account_name: '' } }
      end

      specify { assigns(:bank_information).errors.size.should eq(1) }
      specify { assigns(:bank_information).account_name.should eq('') }
      specify { response.should render_template('distributor/settings/bank_information') }
    end
  end
end

