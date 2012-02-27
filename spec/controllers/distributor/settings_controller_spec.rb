require 'spec_helper'

describe Distributor::SettingsController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
    @invoice = Fabricate(:invoice, :account => @customer.account)
  end

  describe '#index' do
    before(:each) { get :index, :distributor_id => @distributor.id }
    specify { response.should redirect_to(routes_distributor_settings_url(@distributor)) }
  end

  describe '#routes' do
    before(:each) do
      get :routes, :distributor_id => @distributor.id
    end
    specify { assigns(:routes).should eq(@distributor.routes) }
    specify { assigns(:route).should be_a_new(Route) }
  end

  describe '#boxes' do
    before(:each) do
      get :boxes, :distributor_id => @distributor.id
    end
    specify { assigns(:boxes).should eq(@distributor.boxes) }
    specify { assigns(:box).should be_a_new(Box) }
  end
  
  describe '#contact_info' do
    before(:each) do
      get :contact_info, :distributor_id => @distributor.id
    end
    specify { response.should render_template 'distributor/settings/contact_info' }
  end

  describe '#bank_info' do
    context 'without invoice_information' do
      before(:each) do
        get :bank_info, :distributor_id => @distributor.id
      end
      specify { response.should render_template 'distributor/settings/bank_info' }
      specify { assigns(:invoice_information).should be_a_new(InvoiceInformation) }
    end
    context 'with invoice_information' do
      before(:each) do
        @invoice_information = Fabricate(:invoice_information, distributor: @distributor)
        get :bank_info, :distributor_id => @distributor.id
      end
      specify { assigns(:invoice_information).should eq(@invoice_information) }
    end
  end

end
