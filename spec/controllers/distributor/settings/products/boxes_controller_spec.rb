require 'spec_helper'

describe Distributor::Settings::Products::BoxesController do
  render_views
  sign_in_as_distributor

  before do
    @extras = 2.times.collect{Fabricate(:extra, distributor: @distributor)}
    @extra_ids = @extras.collect(&:id)
    @customer = Fabricate(:customer, distributor: @distributor)
  end
  let(:box) { Fabricate(:box, distributor: @distributor, price: 234) }

  describe '#show' do
    before { get :show }
    specify { response.should be_success }
  end

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          box: {
            name: 'yodas box', price: '246', likes: '1', dislikes: '1', description: "tasty selection of herbs from Yoda's garden.", extras_limit: 0, extra_ids: @extra_ids, all_extras: false
          }
        }
      end

      specify { flash[:notice].should eq('Your new box has heen created.') }
      specify { response.should be_success }
    end

    context 'with invalid params' do
      before { post :create, { box: { name: 'yoda' } } }

      specify { response.should be_success }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before { put :update, { box: { id: box.id, price: 123 } } }

      specify { flash[:notice].should eq('Your box has heen updated.') }
      specify { response.should be_success }
    end

    context 'with invalid params' do
      before { put :update, { box: { id: box.id, name: '' } } }

      specify { response.should be_success }
    end
  end
end


