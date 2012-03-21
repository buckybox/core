require 'spec_helper'

describe Distributor::BoxesController do
  render_views

  as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          box: {
            name: 'yodas box', price: '246', likes: '1', dislikes: '1', available_single: '1', available_weekly: '0',
            available_fourtnightly: '1', description: "tasty selection of herbs from Yoda's garden."
          }
        }
      end

      specify { flash[:notice].should eq('Box was successfully created.') }
      specify { assigns(:box).name.should eq('yodas box') }
      specify { response.should redirect_to(distributor_settings_boxes_url) }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { box: { name: 'yoda' } }
      end

      specify { assigns(:box).name.should eq('yoda') }
      specify { response.should render_template('boxes/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @box = Fabricate(:box, distributor: @distributor, price: 234)
        put :update, { id: @box.id, box: { price: 123 } }
      end

      specify { flash[:notice].should eq('Box was successfully updated.') }
      specify { assigns(:box).price.should eq(123) }
      specify { response.should redirect_to(distributor_settings_boxes_url) }
    end

    context 'with invalid params' do
      before(:each) do
        @box = Fabricate(:box, distributor: @distributor, price: 234)
        put :update, { id: @box.id, box: {name: ''} }
      end

      specify { assigns(:box).price.should eq(234) }
      specify { response.should render_template('boxes/edit') }
    end
  end
end

