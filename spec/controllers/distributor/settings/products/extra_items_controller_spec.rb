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

      specify { expect(flash[:notice]).to eq('Your new extra item has been created.') }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { extra: { name: 'yoda' } }
      end

      specify { expect(response).to be_success }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { extra: { id: @extra.id, price: 123 } }
      end

      specify { expect(flash[:notice]).to eq('Your extra item has been updated.') }
    end

    context 'with invalid params' do
      before(:each) do
        @extra = Fabricate(:extra, distributor: @distributor, price: 234)
        put :update, { extra: { id: @extra.id, name: '' } }
      end

      specify { expect(response).to be_success }
    end
  end
end
