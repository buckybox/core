require 'spec_helper'

describe Customer::OrdersController do
  as_customer

  describe "PUT 'update'" do
    before do
      @id    = Fabricate(:order, quantity: 1, account: @customer.account).id
      @order = { quantity: 3 }
    end

    describe 'with valid params' do
      before { put :update, { id: @id, order: @order } }

      specify { assigns(:order).should be_a(Order) }
      specify { assigns(:order).should be_persisted }
      specify { assigns(:order).quantity.should == 3 }
    end

    describe 'with invalid params' do
      before do
        @order[:frequency] = 'all of the times!'
        put :update, { id: @id, order: @order }
      end

      specify { Order.last.quantity.should == 1 }
      specify { response.should render_template('edit') }
    end
  end
end
