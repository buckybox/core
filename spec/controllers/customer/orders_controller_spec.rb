require 'spec_helper'

describe Customer::OrdersController, :focus do
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
        @order[:frequency] = 'all of the times!'
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
        order.pause!(dates[4])
        put :resume, {id: order.id, account_id: order.account_id, date: dates[3]}
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
end
