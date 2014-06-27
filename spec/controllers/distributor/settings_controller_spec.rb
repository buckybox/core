require 'spec_helper'

describe Distributor::SettingsController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#organisation' do
    before { get :organisation, distributor_id: @distributor.id }

    specify { response.should render_template 'distributor/settings/organisation' }
  end
end
