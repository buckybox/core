require 'spec_helper'

describe Distributor::BoxesController do
  render_views
  as_distributor

  before do
    @extras = 2.times.collect{Fabricate(:extra, distributor: @distributor)}
    @extra_ids = @extras.collect(&:id)
    @customer = Fabricate(:customer, distributor: @distributor)
  end
  let(:box) { Fabricate(:box, distributor: @distributor, price: 234) }

  describe '#show' do
    before { get :show, format: :json, id: box.id }
    specify { response.should be_success }
  end

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          box: {
            name: 'yodas box', price: '246', likes: '1', dislikes: '1', available_single: '1', available_weekly: '0',
            available_fourtnightly: '1', description: "tasty selection of herbs from Yoda's garden.", extras_limit: 0,
            extra_ids: @extra_ids
          }
        }
      end

      specify { flash[:notice].should eq('Box was successfully created.') }
      specify { assigns(:box).name.should eq('yodas box') }
      specify { response.should redirect_to(distributor_settings_boxes_url) }
    end

    context 'with invalid params' do
      before { post :create, { box: { name: 'yoda' } } }

      specify { assigns(:box).name.should eq('yoda') }
      specify { response.should render_template('boxes/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before { put :update, { id: box.id, box: { price: 123 } } }

      specify { flash[:notice].should eq('Box was successfully updated.') }
      specify { assigns(:box).price.should eq(123) }
      specify { response.should redirect_to(distributor_settings_boxes_url) }
    end

    context 'with invalid params' do
      before { put :update, { id: box.id, box: {name: ''} } }

      specify { assigns(:box).price.should eq(234) }
      specify { response.should render_template('boxes/edit') }
    end
  end
end

