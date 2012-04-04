require 'spec_helper'

describe Customer::OrdersController do
  as_customer

  describe "POST 'create'" do
    describe 'with valid params' do
      before do
        order      = { quantity: 1, frequency: 'weekly', completed: true, box_id: 1 }
        start_date = Date.current
        days       = { tuesday: 2, wednesday: 3 }

        post :create, { order: order, start_date: start_date, days: days }
      end

      specify { assigns(:order).should be_a(Order) }
      specify { assigns(:order).should be_persisted }
    end

    describe 'with invalid params' do
      before { post :create, { order: {} } }

      specify { response.should redirect_to(customer_root_url) }
    end
  end

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
      specify { response.should redirect_to(customer_root_url) }
    end
  end
end
