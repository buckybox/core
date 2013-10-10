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

  describe '#organisation' do
    before { get :organisation, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/organisation' }
  end
end
