require 'spec_helper'

describe Distributor::OrdersController do
  sign_in_as_distributor

  context "with mocks" do
    before do
      Distributor.any_instance.stub_chain(:accounts, :find).and_return(
        @account = mock_model(Account, {
          customer: mock_model(Customer, {
            id: 1, delivery_service: @delivery_service = mock_model(DeliveryService)
          }),
          delivery_service: @delivery_service,
          id: 675
      }))
      Distributor.any_instance.stub_chain(:boxes, :count, :zero?).and_return(false)
    end

    describe '#new' do
      it 'should render new' do
        @account.stub_chain(:orders, :build).and_return(Order.new(account_id: @account.id))
        get :new, account_id: @account.id
        expect(response).to render_template('new')
      end
    end

    describe '#edit' do
      it 'should render edit' do
        @order = double('order').as_null_object
        @account.stub_chain(:orders, :find).and_return(@order)
        get :edit, account_id: @account.id, id: 7
        expect(response).to render_template('edit')
      end
    end

    describe '#update' do
      before do
        @order = double('order').as_null_object
        Distributor.any_instance.stub_chain(:orders, :find).and_return(@order)
      end

      def do_update
        put :update, account_id: @account.id, order: { menu: 'roast beef' }, id: 7
      end

      it 'should update order' do
        expect(@order).to receive(:update_attributes).with('menu' => 'roast beef')
        do_update
      end

      it 'should redirect' do
        allow(@order).to receive(:update_attributes).and_return(true)
        do_update
        expect(response).to redirect_to('/distributor/customers/1')
      end

      it 'should render edit' do
        allow(@order).to receive(:update_attributes).and_return(false)
        allow(@order).to receive(:errors).and_return(['error'])
        do_update
        expect(response).to render_template('edit')
      end
    end
  end

  describe '#create' do
    before do
      Fabricate(:box, distributor: @distributor)
    end

    it 'should create an order' do
      box = Fabricate(:box, distributor: @distributor)
      account = Fabricate(:account, customer: Fabricate(:customer, distributor: @distributor))
      post :create, account_id: account.id, order: {account_id: account.id, box_id: box.id, schedule_rule_attributes: {mon: '1', start: '2012-10-27'}}
      expect(assigns(:order).schedule_rule.mon).to be true
      expect(assigns(:order).schedule_rule.start).to eq(Date.parse('2012-10-27'))
    end

    it 'should create an order with exclusions and substitutions' do
      box = Fabricate(:box, distributor: @distributor, likes: true, dislikes: true, substitutions_limit: 2, exclusions_limit: 2)
      account = Fabricate(:account, customer: Fabricate(:customer, distributor: @distributor))
      item_ids = 2.times.collect{|i| Fabricate(:line_item, name: "Item #{i}").id}
      post :create, account_id: account.id, order: {account_id: account.id, box_id: box.id, schedule_rule_attributes: {mon: '1', start: '2012-10-27'},  excluded_line_item_ids: ["", "#{item_ids[0]}"], substituted_line_item_ids: ["", "#{item_ids[1]}"]}
      allow_any_instance_of(ScheduleRule).to receive(:includes?).and_return(true)
      expect(response).to redirect_to([:distributor, account.customer]), assigns(:order).errors.full_messages.join(', ')
    end

    it 'should render new' do
      account = Fabricate(:account, customer: Fabricate(:customer, distributor: @distributor))
      get :new, account_id: account.id
      expect(response).to render_template('new')
    end
  end


  context "pausing" do
    let(:order){Fabricate(:order)}
    describe "#pause" do
      it "should pause the order" do
        date = order.next_occurrences(2, Date.current).last
        put :pause, {id: order.id, account_id: order.account_id, date: date}
        expect(assigns(:order).pause_date).to eq(date)
      end
    end

    describe "#remove_pause" do
      it "should remove the pause from an order" do
        order.pause!(Date.tomorrow)
        put :remove_pause, {id: order.id, account_id: order.account_id}
        expect(order.reload.pause_date).to be_nil
      end
    end

    describe "#resume" do
      it "should resume the order" do
        dates = order.next_occurrences(5, Date.current)
        order.pause!(dates[2])
        put :resume, {id: order.id, account_id: order.account_id, date: dates[4]}
        order.reload
        expect(order.pause_date).to eq(dates[2])
        expect(order.resume_date).to eq(dates[4])
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

  describe "#new" do
    render_views
    it "should show the form" do
      order = Fabricate(:order, account: Fabricate(:account, customer: Fabricate(:customer, distributor: @distributor)))
      get :new, {account_id: order.account_id}
    end
  end
end
