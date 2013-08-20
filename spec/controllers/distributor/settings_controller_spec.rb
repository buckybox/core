require 'spec_helper'

describe Distributor::SettingsController do
  render_views

  as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#routes' do
    before { get :routes, distributor_id: @distributor.id }

    specify { assigns(:routes).should eq(@distributor.routes) }
    specify { assigns(:route).should be_a_new(Route) }
  end

  describe '#boxes' do
    before { get :boxes, distributor_id: @distributor.id }

    specify { assigns(:boxes).should eq(@distributor.boxes) }
    specify { assigns(:box).should be_a_new(Box) }
  end

  describe '#extras' do
    before { get :extras, distributor_id: @distributor.id }

    specify { assigns(:extras).should eq(@distributor.extras.alphabetically) }
    specify { assigns(:extra).should be_a_new(Extra) }
  end

  describe '#business_information' do
    before { get :business_information, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/business_information' }
  end

  describe '#bank_information' do
    context 'without bank_information' do
      before { get :bank_information, distributor_id: @distributor.id }

      specify { response.should render_template 'distributor/settings/bank_information' }
      specify { assigns(:bank_information).should be_a_new(BankInformation) }
    end

    context 'with bank_information' do
      before do
        @bank_information = Fabricate(:bank_information, distributor: @distributor)
        get :bank_information, distributor_id: @distributor.id
      end

      specify { assigns(:bank_information).should eq(@bank_information) }
    end
  end

  describe '#invoice_information' do
    context 'without invoice_information' do
      before { get :invoice_information, distributor_id: @distributor.id }

      specify { response.should render_template 'distributor/settings/invoice_information' }
      specify { assigns(:invoice_information).should be_a_new(InvoiceInformation) }
    end

    context 'with invoice_information' do
      before do
        @invoice_information = Fabricate(:invoice_information, distributor: @distributor)
        get :invoice_information, distributor_id: @distributor.id
      end

      specify { response.should render_template 'distributor/settings/invoice_information' }
      specify { assigns(:invoice_information).should eq(@invoice_information) }
    end
  end

  describe '#stock_list' do
    before { get :stock_list, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/stock_list' }
  end
end
