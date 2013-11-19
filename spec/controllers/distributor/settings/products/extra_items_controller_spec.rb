require 'spec_helper'

describe Distributor::Settings::Products::ExtraItemsController do
  render_views

  sign_in_as_distributor

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          extra: {
            name: 'Eggs', unit: '1/2 doz', price: '246'
          }
        }
      end

      specify { flash[:notice].should eq('Your new extra item has heen created.') }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { extra: { name: 'yoda' } }
      end

      specify { response.should be_success }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { extra: { id: @extra.id, price: 123 } }
      end

      specify { flash[:notice].should eq('Your extra item has heen updated.') }
    end

    context 'with invalid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { extra: { id: @extra.id, name: '' } }
      end

      specify { response.should be_success }
    end
  end
end

