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

end
