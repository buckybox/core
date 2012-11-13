require 'spec_helper'
include Bucky

describe Order do
  let(:order) { Fabricate.build(:order) }

  context 'pausing' do
    describe '#pause!' do
      context 'should create a pause' do
        before do
          @start_date = Date.current + 1.day
          @end_date = Date.current + 3.days
        end
        
        it "should call pause on the schedule_rule" do
          order.schedule_rule.should_receive(:pause!).with(@start_date, @end_date)
          order.pause!(@start_date, @end_date)
        end
      end
    end

    describe '#remove_pause!' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        order.schedule_rule.should_receive(:remove_pause!)
        order.remove_pause!
      end
    end

    describe '#pause_date' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        order.schedule_rule.should_receive(:pause_date)
        order.pause_date
      end
    end

    describe '#resume_date' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        order.schedule_rule.should_receive(:resume_date)
        order.resume_date
      end
    end
  end

  context 'when removing a day' do
    let(:order_scheduling) { order }
    let(:schedule_rule)         { double("schedule_rule", to_hash: { a: 'b' }) }

    before { order_scheduling.stub(schedule_rule: schedule_rule) }

    it "should ask the schedule to remove rules and times for that day" do
      schedule_rule.should_receive(:remove_day).with(:tuesday)
      order.remove_day(:tuesday)
    end
  end

  context 'with default saved order' do
    specify { order.should be_valid }

    context :quantity do
      specify { Fabricate.build(:order, quantity: 0).should_not be_valid }
      specify { Fabricate.build(:order, quantity: -1).should_not be_valid }
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

    context :schedule_rule do
      before do
        order.save
        @route = Fabricate(:route, distributor: order.distributor)
        order.completed = true
        order.active = true
      end

      context :single do
        before do
          order.completed = true

          @schedule_rule = new_single_schedule
          order.schedule_rule = @schedule_rule

          order.save
        end

        specify { order.schedule_rule.should_not be_nil }
        specify { order.schedule_rule.next_occurrence.should_not be_nil }
        specify { order.schedule_rule.next_occurrences(28, Date.current).should eq([order.schedule_rule.next_occurrence]) }
        specify { order.schedule_rule.to_s.should == @schedule_rule.to_s }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
      end

      context :weekly do
        before do
          order.completed = true

          @schedule_rule = new_recurring_schedule
          order.schedule_rule = @schedule_rule

          order.save
        end

        specify { order.schedule_rule.should_not be_nil }
        specify { order.schedule_rule.next_occurrence.should_not be_nil }
        specify { order.schedule_rule.next_occurrences(28, Time.current).size.should eq(28) }
        specify { order.schedule_rule.to_s.should == @schedule_rule.to_s }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
      end

      context :fortnightly do
        before do
          order.completed = true

          @schedule_rule = new_recurring_schedule
          order.schedule_rule = @schedule_rule

          order.save
        end

        specify { order.schedule_rule.should_not be_nil }
        specify { order.schedule_rule.next_occurrence.should_not be_nil }
        specify { order.schedule_rule.to_s.should == @schedule_rule.to_s }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
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
        Order.any_instance.stub(:route_includes_schedule_rule).and_return(true)

        rule_schedule = Fabricate(:schedule_rule, start: Date.current - 2.months)
        @order1 = Fabricate(:order, schedule_rule: rule_schedule)

        rule_schedule = Fabricate(:schedule_rule, start: Date.current - 2.months)
        rule_schedule.pause!(Time.current + 1.month)
        @order2 = Fabricate(:order, schedule_rule: rule_schedule)

        rule_schedule = Fabricate(:schedule_rule, start: Date.current - 2.months)
        rule_schedule.pause!(Time.current - 1.month)
        @order3 = Fabricate(:order, schedule_rule: rule_schedule)

        rule_schedule = Fabricate(:schedule_rule, start: Date.current + 5.days, recur: nil)
        @order4 = Fabricate(:order, schedule_rule: rule_schedule)

        rule_schedule = Fabricate(:schedule_rule, start: Date.current - 5.days, recur: nil)
        @order5 = Fabricate(:order, schedule_rule: rule_schedule)
      end

      specify { expect { Order.deactivate_finished}.to change(Order.active, :count).by(-2) }

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

  context 'order requests' do
    before do
      Box.any_instance.stub(:likes?).and_return(true)
      Box.any_instance.stub(:dislikes?).and_return(true)
    end

    describe '#update_exclusions' do
      before do
        order.save
        @e1 = Fabricate(:exclusion, order: order)
        @e2 = Fabricate(:exclusion, order: order)
        @e3 = Fabricate(:exclusion, order: order)
      end

      context 'change exclusions' do
        before do
          @e1_id = @e1.line_item_id
          @e2_id = @e2.line_item_id
          @e3_id = @e3.line_item_id
          @e4_id = Fabricate(:line_item).id

          order.update_exclusions([@e1_id, @e4_id])
          order.save
        end

        specify { order.exclusions.map(&:line_item_id).should == [@e1_id, @e4_id] }
      end

      context 'remove exlusions' do
        before do
          order.update_exclusions(nil)
          order.save
        end

        specify { order.exclusions.map(&:line_item_ids).should == [] }
      end
    end

    describe '#update_substitutions' do
      before do
        order.save
        @s1 = Fabricate(:substitution, order: order)
        @s2 = Fabricate(:substitution, order: order)
        @s3 = Fabricate(:substitution, order: order)
      end

      context 'change substitutions' do
        before do
          @s1_id = @s1.line_item_id
          @s2_id = @s2.line_item_id
          @s3_id = @s3.line_item_id
          @s4_id = Fabricate(:line_item).id

          order.update_substitutions([@s1_id, @s4_id])
          order.save
        end

        specify { order.substitutions.map(&:line_item_id).should == [@s1_id, @s4_id] }
      end

      context 'remove substitutions' do
        before do
          order.update_substitutions(nil)
          order.save
        end

        specify { order.substitutions.map(&:line_item_ids).should == [] }
      end
    end
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
      @params.merge!(order_extras: @order_extras, schedule_rule_attributes: Fabricate.attributes_for(:schedule_rule_weekly))
      @params.except!(:schedule_rule_id)
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

    context "predicted_order_extras" do
      it "should not return extras if they don't recur and an order occurs before this one" do
        order = Order.create(@params.merge(extras_one_off: true))
        order.predicted_order_extras.size.should eq(2)
        order.predicted_order_extras(order.next_occurrences(2, Date.current)[1]).size.should eq(0)
      end

      it "should return extras if they don't recur and an order doesn't occur before this one" do
        order = Order.create(@params.merge(extras_one_off: true, "schedule_rule_attributes" => {"start" => Date.current + 1.week}))
        order.predicted_order_extras.size.should eq(2)
        order.predicted_order_extras(order.next_occurrence - 1.day).size.should eq(2)
      end

      it "should return extras if extras recur" do
        order = Order.create(@params)
        order.predicted_order_extras.size.should eq(2)
        order.predicted_order_extras(order.next_occurrences(2, Date.current)[1]).size.should eq(2)
      end
    end
  end
end
