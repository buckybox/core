require 'spec_helper'

describe Customer::OrdersController do
  as_customer

  describe "POST 'create'" do
    before do
      @box = mock_model(Box, { extras_limit: 3, extras_unlimited?: false, dislikes?: true, likes?: true })
      Order.any_instance.stub(:box).and_return(@box)

      @order      = { quantity: 1, frequency: 'weekly', completed: true, box_id: 1 }
      @start_date = Date.current
      @days       = { tuesday: 2, wednesday: 3 }
    end

    describe 'with valid params' do
      context 'for a one off order' do
        before do
          @order[:frequency] = 'single'
          post :create, { order: @order, start_date: @start_date }
        end

        specify { assigns(:order).should be_a(Order) }
        specify { assigns(:order).should be_persisted }
      end

      context 'for a reccuring order' do
        before { post :create, { order: @order, start_date: @start_date, days: @days } }

        specify { assigns(:order).should be_a(Order) }
        specify { assigns(:order).should be_persisted }
      end
    end

    describe 'with invalid params' do
      before { @order.delete(:box_id) }

      context 'for a one off order' do
        before do
          @order[:frequency] = 'single'
          post :create, { order: @order, start_date: @start_date }
        end

        specify { response.should render_template('new') }
      end

      context 'for a reccuring order' do
        before { post :create, { order: @order, start_date: @start_date } }

        specify { response.should render_template('new') }
      end
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
      specify { response.should render_template('edit') }
    end
  end
end
