require 'spec_helper'

describe Distributor::SettingsController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
    @invoice = Fabricate(:invoice, :account => @customer.account)
  end

  context 'visiting Distributor Settings' do
    it 'should redirect index to routes' do
      get :index, :distributor_id => @distributor.id
      response.should redirect_to(routes_distributor_settings_url(@distributor))
    end
  end

  context 'routes' do
    it 'should show routes and provide new form' do
      get :routes, :distributor_id => @distributor.id
      assigns(:route).should be_a_new(Route)
      assigns(:routes).should == @distributor.routes
    end
  end
end
