require 'spec_helper'

describe Distributor::InvoiceInformationController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
  end

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        InvoiceInformation.any_instance.stub(:valid?).and_return(true)
        post :create, {distributor_id: @distributor.id, invoice_information: {gst_number: '123-456-789'}}
      end
      specify { flash[:notice].should eq("Invoicing Info was successfully created.") }
      specify { assigns(:invoice_information).gst_number.should eq('123-456-789') }
      specify { response.should redirect_to(invoicing_info_distributor_settings_url(@distributor)) }
    end
    context 'with invalid params' do
      before(:each) do
        post :create, {distributor_id: @distributor.id, invoice_information: {gst_number: ''}}
      end
      specify { assigns(:invoice_information).errors[:gst_number].size.should eq(1)}
      specify { assigns(:invoice_information).gst_number.should eq('') }
      specify { response.should render_template('distributor/settings/invoicing_info') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @invoice_information = Fabricate(:invoice_information, distributor: @distributor, gst_number: '000-000-000')
        put :update, {distributor_id: @distributor.id, invoice_information: {gst_number: '123-456-789'}}
      end
      specify { flash[:notice].should eq("Invoicing Info was successfully updated.") }
      specify { assigns(:invoice_information).gst_number.should eq('123-456-789') }
      specify { response.should redirect_to(invoicing_info_distributor_settings_path(@distributor)) }
    end
    context 'with invalid params' do
      before(:each) do
        @invoice_information = Fabricate(:invoice_information, distributor: @distributor, gst_number: '000-000-000')
        put :update, {distributor_id: @distributor.id, invoice_information: {gst_number: ''}}
      end
      specify { assigns(:invoice_information).errors.size.should eq(1) }
      specify { assigns(:invoice_information).gst_number.should eq('') }
      specify { response.should render_template('distributor/settings/invoicing_info') }
    end
  end
end
