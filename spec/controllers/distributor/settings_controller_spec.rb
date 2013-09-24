require 'spec_helper'

describe Distributor::SettingsController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#delivery_services' do
    before { get :delivery_services, distributor_id: @distributor.id }

    specify { assigns(:delivery_services).should eq(@distributor.delivery_services) }
    specify { assigns(:delivery_service).should be_a_new(DeliveryService) }
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

  describe '#organisation' do
    before { get :organisation, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/organisation' }
  end

  describe '#customer_preferences' do
    before { get :customer_preferences, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/customer_preferences' }
  end
end
