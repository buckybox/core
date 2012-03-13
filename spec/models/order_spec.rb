require 'spec_helper'
include IceCube

describe Order do
  before { @order = Fabricate(:order) }

  specify { @order.should be_valid }
  specify { Fabricate(:active_order).should be_valid }

  context :quantity do
    specify { Fabricate.build(:order, :quantity => 0).should_not be_valid }
    specify { Fabricate.build(:order, :quantity => -1).should_not be_valid }
  end

  context :frequency do
    Order::FREQUENCIES.each do |f|
      specify { Fabricate.build(:order, :frequency => f).should be_valid }
    end
    specify { Fabricate.build(:order, :frequency => 'yearly').should_not be_valid }
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

  context '#self.create_schedule' do
    Delorean.time_travel_to(Date.parse('2013-02-02')) do
      context 'exceptions' do
        %w(weekly fortnightly monthly).each do |frequency|
          specify { expect { Order.create_schedule(Time.current, frequency) }.should raise_error }
        end
      end

      specify { Order.create_schedule(Time.current, 'single').to_s.should == Time.current.strftime("%B %e, %Y") }
      specify { Order.create_schedule(Time.current, 'weekly', [1, 3]).to_s.should == 'Weekly on Mondays and Wednesdays' }
      specify { Order.create_schedule(Time.current, 'fortnightly', [1, 3]).to_s.should == 'Every 2 weeks on Mondays and Wednesdays' }
      specify { Order.create_schedule(Time.current, 'monthly', [1, 3]).to_s.should == 'Monthly on the 1st Monday when it is the 1st Wednesday' }
    end
  end

  context :schedule do
    before do
      @route = Fabricate(:route, :distributor => @order.distributor)
      @order.completed = true
      @order.active = true
    end

    describe 'new schedule' do
      before do
        @schedule = BuckySchedule.new
        @schedule.add_recurrence_rule(Rule.weekly.day(:monday, :friday))
        @order.schedule = @schedule
        @order.save
      end

      specify { @order.schedule.to_hash.should == @schedule.to_hash }
    end

    describe 'change schedule' do
      before do
        @schedule = @order.schedule
        @schedule.add_recurrence_time(Time.current + 5.days)
        @schedule.add_recurrence_rule(Rule.weekly(2).day(:monday, :tuesday))
        @order.schedule = @schedule
        @order.save
      end

      specify { @order.schedule.to_hash.should == @schedule.to_hash }
    end

    context :single do
      before do
        @order.frequency = 'single'
        @order.completed = true

        @schedule = BuckySchedule.new(new_single_schedule)
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
    end

    context :weekly do
      before do
        @order.frequency = 'weekly'
        @order.completed = true

        @schedule = BuckySchedule.new(new_recurring_schedule)
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
    end

    context :fortnightly do
      before do
        @order.frequency = 'fortnightly'
        @order.completed = true

        @schedule = BuckySchedule.new(new_recurring_schedule)
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
    end
  end

  context :schedule_transaction do
    before do
      schedule = BuckySchedule.new
      schedule.add_recurrence_rule(Rule.weekly.day(:monday, :friday))
      @order.schedule = schedule
    end

    specify { expect { @order.save }.should change(OrderScheduleTransaction, :count).by(1) }
  end

  context 'scheduled_delivery' do
    before do
      @schedule = @order.schedule
      delivery_list = Fabricate(:delivery_list, :date => Date.current + 5.days)
      @delivery = Fabricate(:delivery, :delivery_list => delivery_list)
      @order.add_scheduled_delivery(@delivery)
      @order.save
    end

    describe '#add_scheduled_delivery' do
      specify { @order.schedule.occurs_on?(@delivery.date.to_time).should be_true }
      specify { @order.schedule.occurs_on?((@delivery.date - 1.day).to_time).should_not be_true }
    end

    describe '#remove_scheduled_delivery' do
      before do
        @order.remove_scheduled_delivery(@delivery)
        @order.save
      end

      specify { @order.schedule.occurs_on?(@delivery.date.to_time).should_not be_true }
    end
  end

  describe '#string_pluralize' do
    context "when the quantity is 1" do
      before { @order.quantity = 1 }
      specify { @order.string_pluralize.should == "1 #{@order.box.name}" }
    end

    [0, 2].each do |q|
      context "when the quantity is #{q}" do
        before { @order.quantity = q }
        specify { @order.string_pluralize.should == "#{q} #{@order.box.name}s" }
      end
    end
  end

  describe '#deactivate_finished' do
    before do
      rule_schedule = BuckySchedule.new(Time.current - 2.months)
      rule_schedule.add_recurrence_rule(Rule.daily(3))

      rule_schedule_no_end_date = rule_schedule.clone
      @order1 = Fabricate(:active_order, :schedule => rule_schedule_no_end_date)

      rule_schedule_end_date_future = rule_schedule.clone
      rule_schedule_end_date_future.end_time = (Time.current + 1.month)
      @order2 = Fabricate(:active_order, :schedule => rule_schedule_end_date_future)

      rule_schedule_end_date_past = rule_schedule.clone
      rule_schedule_end_date_past.end_time = (Time.current - 1.month)
      @order3 = Fabricate(:active_order, :schedule => rule_schedule_end_date_past)

      time_schedule_future = BuckySchedule.new(Time.current - 2.months)
      time_schedule_future.add_recurrence_time(Time.current + 5.days)
      @order4 = Fabricate(:active_order, :schedule => time_schedule_future)

      time_schedule_past = BuckySchedule.new(Time.current - 2.months)
      time_schedule_past.add_recurrence_time(Time.current - 5.days)
      @order5 = Fabricate(:active_order, :schedule => time_schedule_past)
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
      @order = order_with_deliveries
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

