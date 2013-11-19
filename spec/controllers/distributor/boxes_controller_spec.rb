require 'spec_helper'

describe Distributor::BoxesController do
  render_views
  sign_in_as_distributor

  let(:box) { Fabricate(:box, distributor: @distributor) }

  describe '#show' do
    before { get :show, format: :json, id: box.id }
    specify { response.should be_success }
  end
end

