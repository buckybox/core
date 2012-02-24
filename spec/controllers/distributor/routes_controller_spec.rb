require 'spec_helper'

describe Distributor::RoutesController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
    @invoice = Fabricate(:invoice, :account => @customer.account)
  end

  it 'should create route and redirect to route settings' do
    Route.any_instance.stub(:valid?).and_return(true)
    post :create, distributor_id: @distributor.id
    assigns(:route).should_not be_new_record
    flash[:notice].should eq("Route was successfully created.")
    response.should redirect_to(routes_distributor_settings_url)
  end
end

