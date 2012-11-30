require 'spec_helper'

describe Customer::OrdersController do
  render_views
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
        @order[:quantity] = 'all of the times!'
        put :update, { id: @id, order: @order }
      end

      specify { Order.last.quantity.should == 1 }
      specify { response.should render_template('edit') }
    end
  end

  context :pausing do
    let(:order){Fabricate(:order)}
    describe "#pause" do
      it "should pause the order" do
        date = order.next_occurrences(2, Date.current).last
        put :pause, {id: order.id, account_id: order.account_id, date: date}
        assigns(:order).pause_date.should eq(date)
      end
    end

    describe "#remove_pause" do
      it "should remove the pause from an order" do
        order.pause!(Date.tomorrow)
        put :remove_pause, {id: order.id, account_id: order.account_id}
        order.reload.pause_date.should be_nil
      end
    end
    
    describe "#resume" do
      it "should resume the order" do
        dates = order.next_occurrences(5, Date.current)
        order.pause!(dates[2])
        put :resume, {id: order.id, account_id: order.account_id, date: dates[4]}
        order.reload
        order.pause_date.should eq(dates[2])
        order.resume_date.should eq(dates[4])
      end
    end

    describe "#remove_resume" do
      it "should resume the order" do
        dates = order.next_occurrences(5, Date.current)
        order.pause!(dates[4], dates[5])
        post :remove_resume, {id: order.id, account_id: order.account_id}
      end
    end
  end

  describe "#deactivate" do
    let(:order){ Fabricate(:order, account: @customer.account)}

    it "should deactivate the order" do
      d = @customer.distributor
      d.customer_can_remove_orders = true
      d.save

      put :deactivate, {id: order.id}
      order.reload.active.should be_false
    end

    it "should only allow deactivating your own orders" do
      other_customer = Fabricate(:customer)
      other_order = Fabricate(:order, account: other_customer.account)
      expect{put :deactivate, {id: other_order.id}}.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should only deactivate if enabled via admin's distributor settings" do
      assert !@customer.distributor.customer_can_remove_orders, "This should be false for the test"
      put :deactivate, {id: order.id}
      order.reload.active.should be_true
    end
  end
end
