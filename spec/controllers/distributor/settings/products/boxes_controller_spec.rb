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
        expect do
          post :create, {
            box: {
              "name" => "Yoda", "price" => "234.00", "description" => "Nom nom nom", "visible" => "1", "dislikes" => "1", "exclusions_limit" => "3", "likes" => "1", "substitutions_limit" => "1", "extras_allowed" => "1", "extras_limit" => "4", "all_extras" => "0", "extra_ids" => @extra_ids
            }
          }
        end.to change { @distributor.boxes.count }.by(1)
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


