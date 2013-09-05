require 'spec_helper'

describe Distributor::BankInformationController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#update' do
    context 'with valid params' do
      before do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_deposit: { account_name: 'company account' } }
      end

      specify { flash[:notice].should eq('Your Bank Deposit settings were successfully updated.') }
      specify { response.should redirect_to(distributor_settings_payments_url) }
    end

    context 'with invalid params' do
      before do
        Fabricate(:bank_information, distributor: @distributor, account_name: 'companies accounts')
        put :update, { bank_deposit: { account_name: '' } }
      end

      specify { response.should render_template('distributor/settings/payments') }
    end
  end
end

