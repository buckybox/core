require 'spec_helper'

describe Distributor::InvoiceInformationController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, :distributor => @distributor) }

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          invoice_information: {
            gst_number: '123-456-789', billing_address_1: '1 St.', billing_suburb: 'suburb',
            billing_city: 'city', billing_postcode: '1999', phone: '123-123-1234'
          }
        }
      end

      specify { flash[:notice].should eq('Invoice information was successfully created.') }
      specify { assigns(:invoice_information).gst_number.should eq('123-456-789') }
      specify { response.should redirect_to(distributor_settings_invoice_information_url) }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { invoice_information: { gst_number: '' } }
      end

      specify { assigns(:invoice_information).gst_number.should eq('') }
      specify { response.should render_template('distributor/settings/invoice_information') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        Fabricate(:invoice_information, distributor: @distributor, gst_number: '000-000-000')
        put :update, { invoice_information: { gst_number: '123-456-789' } }
      end

      specify { flash[:notice].should eq('Invoice information was successfully updated.') }
      specify { assigns(:invoice_information).gst_number.should eq('123-456-789') }
      specify { response.should redirect_to(distributor_settings_invoice_information_url) }
    end

    context 'with invalid params' do
      before(:each) do
        Fabricate(:invoice_information, distributor: @distributor, gst_number: '000-000-000')
        put :update, { invoice_information: { gst_number: '' } }
      end

      specify { assigns(:invoice_information).gst_number.should eq('') }
      specify { response.should render_template('distributor/settings/invoice_information') }
    end
  end
end
