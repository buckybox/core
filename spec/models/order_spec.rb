require 'spec_helper'
include Bucky

describe Order do
  let(:order) { Fabricate.build(:order) }

  context 'when removing a day' do
    let(:order_scheduling) { order }
    let(:schedule)         { double("schedule", to_hash: { a: 'b' }) }

    before { order_scheduling.stub(schedule: schedule) }

    it "should ask the schedule to remove rules and times for that day" do
      schedule.should_receive(:remove_recurrence_rule_day).with(:tuesday)
      schedule.should_receive(:remove_recurrence_times_on_day).with(:tuesday)
      order.remove_day(:tuesday)
    end
  end

  context 'with default saved order' do
    specify { order.should be_valid }

    context :quantity do
      specify { Fabricate.build(:order, quantity: 0).should_not be_valid }
      specify { Fabricate.build(:order, quantity: -1).should_not be_valid }
    end

    context :frequency do
      Order::FREQUENCIES.each do |f|
        specify { Fabricate.build(:order, frequency: f).should be_valid }
      end

      specify { Fabricate.build(:order, frequency: 'yearly').should_not be_valid }
    end

    context :price do
      # Default box price is $10
      ORDER_PRICE_PERMUTATIONS = [
        { discount: 0.05, fee: 5, quantity: 5, individual_price: 14.25, price: 71.25 },
        { discount: 0.05, fee: 5, quantity: 1, individual_price: 14.25, price: 14.25 },
        { discount: 0.05, fee: 0, quantity: 5, individual_price:  9.50, price: 47.50 },
        { discount: 0.05, fee: 0, quantity: 1, individual_price:  9.50, price:  9.50 },
        { discount: 0.00, fee: 5, quantity: 5, individual_price: 15.00, price: 75.00 },
        { discount: 0.00, fee: 5, quantity: 1, individual_price: 15.00, price: 15.00 },
        { discount: 0.00, fee: 0, quantity: 5, individual_price: 10.00, price: 50.00 },
        { discount: 0.00, fee: 0, quantity: 1, individual_price: 10.00, price: 10.00 }
      ]

      ORDER_PRICE_PERMUTATIONS.each do |pp|
        context "where discount is #{pp[:discount]}, fee is #{pp[:fee]}, and quantity is #{pp[:quantity]}" do
          before do
            route = Fabricate(:route, fee: pp[:fee])
            customer = Fabricate(:customer, discount: pp[:discount], route: route)
            @order = Fabricate(:order, quantity: pp[:quantity], account: customer.account)
          end

          specify { @order.individual_price.should == pp[:individual_price] }
          specify { @order.price.should == pp[:price] }
        end
      end
    end

    context '#create_schedule' do
      Delorean.time_travel_to(Date.parse('2013-02-02')) do
        before { order.save }

        context 'exceptions' do
          %w(weekly fortnightly monthly).each do |frequency|
            specify { order.create_schedule(Time.current, frequency).should be_nil }
          end
        end

        specify { order.create_schedule(Time.current, 'single').to_s.should == Time.current.strftime("%B %e, %Y") }
        specify { order.create_schedule(Time.current, 'weekly', [1, 3]).to_s.should == 'Weekly on Mondays and Wednesdays' }
        specify { order.create_schedule(Time.current, 'fortnightly', [1, 3]).to_s.should == 'Every 2 weeks on Mondays and Wednesdays' }
        specify { order.create_schedule(Time.current, 'monthly', [1, 3]).to_s.should == 'Monthly on the 1st Monday when it is the 1st Wednesday' }
      end
    end

    context :schedule do
      before do
        order.save
        @route = Fabricate(:route, distributor: order.distributor)
        order.completed = true
        order.active = true
      end

      describe 'new schedule' do
        before do
          @schedule = Bucky::Schedule.new
          @schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:monday, :friday))
          order.schedule = @schedule
          order.save
        end

        specify { order.schedule.to_hash.should == @schedule.to_hash }
      end

      describe 'change schedule' do
        before do
          @schedule = order.schedule
          @schedule.add_recurrence_time(Time.current + 5.days)
          @schedule.add_recurrence_rule(IceCube::Rule.weekly(2).day(:monday, :tuesday))
          order.schedule = @schedule
          order.save
        end

        specify { order.schedule.to_hash.should == @schedule.to_hash }
      end

      context :single do
        before do
          order.frequency = 'single'
          order.completed = true

          @schedule = new_single_schedule
          order.schedule = @schedule

          order.save
        end

        specify { order.schedule.should_not be_nil }
        specify { order.schedule.next_occurrence.should_not be_nil }
        specify { order.schedule.next_occurrences(28, Time.current).should eq([order.schedule.next_occurrence]) }
        specify { order.schedule.to_s.should == @schedule.to_s }
        specify { order.schedule.next_occurrence == @schedule.next_occurrence }
      end

      context :weekly do
        before do
          order.frequency = 'weekly'
          order.completed = true

          @schedule = new_recurring_schedule
          order.schedule = @schedule

          order.save
        end

        specify { order.schedule.should_not be_nil }
        specify { order.schedule.next_occurrence.should_not be_nil }
        specify { order.schedule.next_occurrences(28, Time.current).size.should eq(28) }
        specify { order.schedule.to_s.should == @schedule.to_s }
        specify { order.schedule.next_occurrence == @schedule.next_occurrence }
      end

      context :fortnightly do
        before do
          order.frequency = 'fortnightly'
          order.completed = true

          @schedule = new_recurring_schedule
          order.schedule = @schedule

          order.save
        end

        specify { order.schedule.should_not be_nil }
        specify { order.schedule.next_occurrence.should_not be_nil }
        specify { order.schedule.to_s.should == @schedule.to_s }
        specify { order.schedule.next_occurrence == @schedule.next_occurrence }
      end
    end

    context :schedule_transaction do
      before do
        schedule = Bucky::Schedule.new
        schedule.add_recurrence_rule(IceCube::Rule.weekly.day(:monday, :friday))
        order.schedule = schedule
      end

      specify { expect { order.save }.should change(OrderScheduleTransaction, :count).by(1) }
    end

    context 'scheduled_delivery' do
      before do
        @schedule = order.schedule
        delivery_list = Fabricate(:delivery_list, date: Date.current + 5.days)
        @delivery = Fabricate(:delivery, delivery_list: delivery_list)
        order.add_scheduled_delivery(@delivery)
        order.save
      end

      describe '#add_scheduled_delivery' do
        specify { order.schedule.occurs_on?(@delivery.date.to_time_in_current_zone).should be_true }
        specify { order.schedule.occurs_on?((@delivery.date - 1.day).to_time_in_current_zone).should_not be_true }
      end

      describe '#remove_scheduled_delivery' do
        before do
          order.remove_scheduled_delivery(@delivery)
          order.save
        end

        specify { order.schedule.occurs_on?(@delivery.date.to_time_in_current_zone).should_not be_true }
      end
    end

    describe '#string_pluralize' do
      context "when the quantity is 1" do
        before { order.quantity = 1 }
        specify { order.string_pluralize.should == "1 #{order.box.name}" }
      end

      [0, 2].each do |q|
        context "when the quantity is #{q}" do
          before { order.quantity = q }
          specify { order.string_pluralize.should == "#{q} #{order.box.name}s" }
        end
      end
    end

    describe '#deactivate_finished' do
      before do
        rule_schedule = new_recurring_schedule(Time.current - 2.months)

        @order1 = Fabricate(:order, schedule: rule_schedule)

        rule_schedule.end_time = (Time.current + 1.month)
        @order2 = Fabricate(:order, schedule: rule_schedule)

        rule_schedule.end_time = (Time.current - 1.month)
        @order3 = Fabricate(:order, schedule: rule_schedule)

        time_schedule_future = Bucky::Schedule.new(Time.current - 2.months)
        time_schedule_future.add_recurrence_time(Time.current + 5.days)
        @order4 = Fabricate(:order, schedule: time_schedule_future)

        time_schedule_past = Bucky::Schedule.new(Time.current - 2.months)
        time_schedule_past.add_recurrence_time(Time.current - 5.days)
        @order5 = Fabricate(:order, schedule: time_schedule_past)
      end

      specify { expect { Order.deactivate_finished }.should change(Order.active, :count).by(-2) }

      describe 'individually' do
        before { Order.deactivate_finished }

        specify { @order1.reload.active.should be_true }
        specify { @order2.reload.active.should be_true }
        specify { @order3.reload.active.should be_false }
        specify { @order4.reload.active.should be_true }
        specify { @order5.reload.active.should be_false }
      end
    end

    describe "#future_deliveries" do
      before(:each) do
        @order = Fabricate(:active_recurring_order)
        @end_date = 4.weeks.from_now(1.day.ago)
        @results = @order.future_deliveries(@end_date)
      end

      it "returns a hash with date, price and description" do
        hash = @results.first
        hash[:date].should >= Date.current
      end

      it "includes deliveries within date range" do
        @results.last[:date].should <= @end_date.to_date
      end
    end
  end

  describe '#update_exclusions' do
    before do
      order.save
      @e1 = Fabricate(:exclusion, order: order)
      @e2 = Fabricate(:exclusion, order: order)
      @e3 = Fabricate(:exclusion, order: order)

      @e1_id = @e1.line_item_id
      @e2_id = @e2.line_item_id
      @e3_id = @e3.line_item_id
      @e4_id = Fabricate(:line_item).id

      order.update_exclusions([@e1_id, @e4_id])
      order.save
    end

    specify { order.exclusion_ids.should == [@e1_id, @e4_id] }
  end

  describe '#update_substitutions' do
    before do
      order.save
      @s1 = Fabricate(:substitution, order: order)
      @s2 = Fabricate(:substitution, order: order)
      @s3 = Fabricate(:substitution, order: order)

      @s1_id = @s1.line_item_id
      @s2_id = @s2.line_item_id
      @s3_id = @s3.line_item_id
      @s4_id = Fabricate(:line_item).id

      order.update_substitutions([@s1_id, @s4_id])
      order.save
    end

    specify { order.substitution_ids.should == [@s1_id, @s4_id] }
  end

  describe '.pack_and_update_extras' do
    it "removes extras when it is a one off and returns hash" do
      order = Fabricate.build(:order, extras_one_off: true)
      order.stub(:order_extras, :collect).and_return([{count: 3, name: "iPhone 4s", unit: "one", price_cents: 99995, currency: "NZD"}, {count: 1, name: "Apple", unit: "kg", price_cents: 295, currency: "NZD"}])

      order.should_receive(:clear_extras)
      order.pack_and_update_extras.should eq([{count: 3, name: "iPhone 4s", unit: "one", price_cents: 99995, currency: "NZD"}, {count: 1, name: "Apple", unit: "kg", price_cents: 295, currency: "NZD"}])
    end

    it "keeps extras when it is a recurring order and returns hash" do
      order = Fabricate.build(:order, extras_one_off: false)
      order.stub(:order_extras, :collect).and_return([{count: 3, name: "iPhone 4s", unit: "one", price_cents: 99995, currency: "NZD"}, {count: 1, name: "Apple", unit: "kg", price_cents: 295, currency: "NZD"}])

      order.should_not_receive(:clear_extras)
      order.pack_and_update_extras.should eq([{count: 3, name: "iPhone 4s", unit: "one", price_cents: 99995, currency: "NZD"}, {count: 1, name: "Apple", unit: "kg", price_cents: 295, currency: "NZD"}])
    end
  end

  context "with extras" do
    before do
      @distributor = Fabricate(:distributor)
      @extras = 2.times.collect{Fabricate(:extra, distributor: @distributor)}
      @extra_ids = @extras.collect(&:id)

      @order_extras = {@extra_ids.first.to_s => {count: 3},
                      @extra_ids.last.to_s => {count: 1}}

      @box = Fabricate(:box, extras_limit: 5, distributor: @distributor)

      @params = Fabricate.attributes_for(:order, box_id: @box.id)
      @params.merge!(order_extras: @order_extras)
    end

    it "should create order_extras from extra_ids" do
      order = Order.create(@params)
      order.should be_valid
      order.order_extras.collect(&:extra_id).sort.should eq(@extra_ids.sort)

      order.extras_count.should eq(4)
      order.order_extras.find_by_extra_id(@extra_ids.first).count.should eq(3)
      order.order_extras.find_by_extra_id(@extra_ids.last).count.should eq(1)
    end

    it "should validate extras limit" do
      Box.find(@params[:box_id]).update_attribute(:extras_limit, 3)

      order = Order.create(@params)
      order.should_not be_valid
      order.errors[:base].should include("There is more than 3 extras for this box")
    end

    it "should update extras and delete old ones" do
      order = Order.create(@params)
      order.should be_valid

      @order_extras[@extra_ids.first.to_s][:count] = 0
      new_extra = Fabricate(:extra, distributor: @distributor)
      @order_extras.merge!(new_extra.id => {count: 2})

      order.update_attributes(order_extras: @order_extras)
      order.should be_valid

      order.order_extras.collect(&:extra_id).should_not include(@extra_ids.first)
      order.extras_count.should eq(3)
    end
  end
end
