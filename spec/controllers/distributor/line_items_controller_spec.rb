require 'spec_helper'

describe Distributor::LineItemsController do
  render_views

  as_distributor

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, { stock_list: { names: "Apples\nOranges\nGrapes" } }
      end

      specify { flash[:notice].should eq('The stock list was successfully updated.') }
      specify { response.should redirect_to(distributor_settings_stock_list_url(edit: true)) }
    end

    context 'with valid params' do
      before do
        post :create, { stock_list: { names: "" } }
      end

      specify { flash[:error].should eq('Could not update the stock list.') }
      specify { response.should redirect_to(distributor_settings_stock_list_url(edit: true)) }
    end
  end
end
