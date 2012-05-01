require 'spec_helper'

describe Distributor::ExtrasController do
  render_views

  as_distributor

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          extra: {
            name: 'Eggs', unit: '1/2 doz', price: '246'
          }
        }
      end

      specify { flash[:notice].should eq('Extra was successfully created.') }
      specify { assigns(:extra).name.should eq('Eggs') }
      specify { response.should redirect_to(distributor_settings_extras_url) }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { extra: { name: 'yoda' } }
      end

      specify { assigns(:extra).name.should eq('yoda') }
      specify { response.should render_template('extras/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { id: @extra.id, extra: { price: 123 } }
      end

      specify { flash[:notice].should eq('Extra was successfully updated.') }
      specify { assigns(:extra).price.should eq(123) }
      specify { response.should redirect_to(distributor_settings_extras_url) }
    end

    context 'with invalid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { id: @extra.id, extra: {name: ''} }
      end

      specify { assigns(:extra).price.should eq(234) }
      specify { response.should render_template('extras/edit') }
    end
  end
end

