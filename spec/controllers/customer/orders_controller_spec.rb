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

      specify { assigns(:order).should be_a(Order) }
      specify { assigns(:order).should_not be_persisted }
    end
  end

  describe "PUT 'update'" do
    describe 'with valid params' do
      it 'creates a new order' do
      end
    end

    describe 'with invalid params' do
      it 'creates a new order' do
      end
    end
  end
end
