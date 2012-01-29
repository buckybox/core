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

  context :schedule do
    before do
      @route = Fabricate(:route, :distributor => @order.distributor)
      @order.completed = true
      @order.active = true
    end

    describe 'new schedule' do
      before do
        @schedule = Schedule.new
        @schedule.add_recurrence_rule(Rule.weekly.day(:monday, :friday))
        @order.schedule = @schedule
        @order.save
      end

      specify { @order.schedule.to_hash.should == @schedule.to_hash }
    end

    describe 'change schedule' do
      before do
        @schedule = @order.schedule
        @schedule.add_recurrence_date(Time.now + 5.days)
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

        @schedule = new_single_schedule
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
      specify { @order.should have(1).delivery }
    end

    context :weekly do
      before do
        @order.frequency = 'weekly'
        @order.completed = true

        @schedule = new_recurring_schedule
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
      specify { @order.should have(1).delivery }
    end

    context :fortnightly do
      before do
        @order.frequency = 'fortnightly'
        @order.completed = true

        @schedule = new_recurring_schedule
        @order.schedule = @schedule

        @order.save
      end

      specify { @order.schedule.should_not be_nil }
      specify { @order.schedule.next_occurrence.should_not be_nil }
      specify { @order.schedule.to_s.should == @schedule.to_s }
      specify { @order.schedule.next_occurrence == @schedule.next_occurrence }
      specify { @order.should have(1).delivery }
    end
  end

  context :schedule_transaction do
    before do
      schedule = Schedule.new
      schedule.add_recurrence_rule(Rule.weekly.day(:monday, :friday))
      @order.schedule = schedule
    end

    specify { expect { @order.save }.should change(OrderScheduleTransaction, :count).by(1) }
  end

  context 'scheduled_delivery' do
    before do
      @schedule = @order.schedule
      @delivery = Fabricate(:delivery, :date => Date.today + 5.days)
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

  describe '#delivery_for_date' do
    before { @delivery = Fabricate(:delivery, :order => @order) }
    specify { @order.delivery_for_date(@delivery.date).should == @delivery }
  end

  describe '#check_status_by_date' do
    before do
      @past_date = Date.today - 2.days
      @future_date = Date.today + 3.days
      @delivery = Fabricate(:delivery, :order => @order, :date => @past_date, :status => 'delivered')

      @schedule = @order.schedule
      @schedule.start_date = Time.now - 4.weeks #make sure the start date is well befor ether test date
      @schedule.add_recurrence_date(@past_date.to_time)
      @schedule.add_recurrence_date(@future_date.to_time)

      @order.schedule = @schedule
      @order.save
    end

    specify { @order.check_status_by_date(@past_date).should == 'delivered' }
    specify { @order.check_status_by_date(@future_date).should == 'pending' }
  end

  describe '#deactivate_finished' do
    before do
      rule_schedule = Schedule.new(Time.now - 2.months)
      rule_schedule.add_recurrence_rule(Rule.daily(3))

      rule_schedule_no_end_date = rule_schedule.clone
      @order1 = Fabricate(:active_order, :schedule => rule_schedule_no_end_date)

      rule_schedule_end_date_future = rule_schedule.clone
      rule_schedule_end_date_future.end_time = (Time.now + 1.month)
      @order2 = Fabricate(:active_order, :schedule => rule_schedule_end_date_future)

      rule_schedule_end_date_past = rule_schedule.clone
      rule_schedule_end_date_past.end_time = (Time.now - 1.month)
      @order3 = Fabricate(:active_order, :schedule => rule_schedule_end_date_past)

      time_schedule_future = Schedule.new(Time.now - 2.months)
      time_schedule_future.add_recurrence_time(Time.now + 5.days)
      @order4 = Fabricate(:active_order, :schedule => time_schedule_future)

      time_schedule_past = Schedule.new(Time.now - 2.months)
      time_schedule_past.add_recurrence_time(Time.now - 5.days)
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
end

