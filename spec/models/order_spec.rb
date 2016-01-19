require 'spec_helper'
include Bucky

describe Order do
  let(:order) { Fabricate(:order) }
  let(:everyday_order) { Fabricate(:recurring_order_everyday, schedule_rule: new_everyday_schedule(Date.parse("2012-09-24"))) }

  describe ".short_code" do
    specify { expect(Order.short_code("box", true, false)).to eq "BOX+D" }
    specify { expect(Order.short_code("box", true, true)).to eq "BOX+D+L" }
    specify { expect(Order.short_code("box", false, true)).to eq "BOX+L" }
    specify { expect(Order.short_code("box", false, false)).to eq "BOX" }
  end

  context 'pausing' do
    describe '#pause!' do
      context 'should create a pause' do
        before do
          @start_date = Date.current + 1.day
          @end_date = Date.current + 3.days
        end

        it "should call pause on the schedule_rule" do
          expect(order.schedule_rule).to receive(:pause!).with(@start_date, @end_date)
          order.pause!(@start_date, @end_date)
        end
      end
    end

    describe '#remove_pause!' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        expect(order.schedule_rule).to receive(:remove_pause!)
        order.remove_pause!
      end
    end

    describe '#pause_date' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        expect(order.schedule_rule).to receive(:pause_date)
        order.pause_date
      end
    end

    describe '#resume_date' do
      it "should delegate to schedule_rule" do
        order.pause!(Date.current + 1.day, Date.current + 3.days)
        expect(order.schedule_rule).to receive(:resume_date)
        order.resume_date
      end
    end

    describe "#possible_resume_dates" do
      it "lists possible dates to resume" do
        allow_any_instance_of(Distributor).to receive(:window_start_from).and_return(Date.parse("2012-10-01"))
        allow_any_instance_of(Distributor).to receive(:advance_days).and_return(3)
        everyday_order.pause!(Date.parse("2012-09-30"))
        expect(everyday_order.possible_resume_dates(1.week).collect(&:first)).to eq ["Thu 4 Oct",
                                                                                     "Fri 5 Oct",
                                                                                     "Sat 6 Oct",
                                                                                     "Sun 7 Oct",
                                                                                     "Mon 8 Oct",
                                                                                     "Tue 9 Oct",
                                                                                     "Wed 10 Oct",
                                                                                     "Thu 11 Oct"]
      end
    end
  end

  context 'when removing a day' do
    let(:order_scheduling) { order }
    let(:schedule_rule) { double("schedule_rule", to_hash: { a: 'b' }) }

    before { order_scheduling.stub(schedule_rule: schedule_rule) }

    it "should ask the schedule to remove rules and times for that day" do
      expect(schedule_rule).to receive(:remove_day).with(:tuesday)
      order.remove_day(:tuesday)
    end
  end

  context 'with default saved order' do
    specify { expect(order).to be_valid }

    context :quantity do
      specify { expect { Fabricate(:order, quantity: 0) }.to raise_error(ActiveRecord::RecordInvalid, /Quantity must be greater than 0/) }
      specify { expect { Fabricate(:order, quantity: -1) }.to raise_error(ActiveRecord::RecordInvalid, /Quantity must be greater than 0/) }
    end

    context :price do
      # Default box price is $10
      ORDER_PRICE_PERMUTATIONS = [
        { discount: 0.05, fee: 5, quantity: 5, individual_price: 14.50, price: 72.50 },
        { discount: 0.05, fee: 5, quantity: 1, individual_price: 14.50, price: 14.50 },
        { discount: 0.05, fee: 0, quantity: 5, individual_price: 9.50, price: 47.50 },
        { discount: 0.05, fee: 0, quantity: 1, individual_price: 9.50, price: 9.50 },
        { discount: 0.00, fee: 5, quantity: 5, individual_price: 15.00, price: 75.00 },
        { discount: 0.00, fee: 5, quantity: 1, individual_price: 15.00, price: 15.00 },
        { discount: 0.00, fee: 0, quantity: 5, individual_price: 10.00, price: 50.00 },
        { discount: 0.00, fee: 0, quantity: 1, individual_price: 10.00, price: 10.00 },
      ].freeze

      ORDER_PRICE_PERMUTATIONS.each do |pp|
        context "where discount is #{pp[:discount]}, fee is #{pp[:fee]}, and quantity is #{pp[:quantity]}" do
          before do
            delivery_service = Fabricate(:delivery_service, fee: pp[:fee])
            customer = Fabricate(:customer, discount: pp[:discount], delivery_service: delivery_service)
            @order = Fabricate(:order, quantity: pp[:quantity], account: customer.account)
          end

          specify { expect(@order.individual_price).to eq pp[:individual_price] }
          specify { expect(@order.price).to eq pp[:price] }
        end
      end
    end

    context :schedule_rule do
      before do
        order.save
        @delivery_service = Fabricate(:delivery_service, distributor: order.distributor)
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

        specify { expect(order.schedule_rule).not_to be_nil }
        specify { expect(order.schedule_rule.next_occurrence).not_to be_nil }
        specify { expect(order.schedule_rule.next_occurrences(28, Date.current)).to eq([order.schedule_rule.next_occurrence]) }
        specify { expect(order.schedule_rule.deliver_on).to eq @schedule_rule.deliver_on }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
      end

      context :weekly do
        before do
          order.completed = true

          @schedule_rule = new_recurring_schedule
          order.schedule_rule = @schedule_rule

          order.save
        end

        specify { expect(order.schedule_rule).not_to be_nil }
        specify { expect(order.schedule_rule.next_occurrence).not_to be_nil }
        specify { expect(order.schedule_rule.next_occurrences(28, Time.current).size).to eq(28) }
        specify { expect(order.schedule_rule.deliver_on).to eq @schedule_rule.deliver_on }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
      end

      context :fortnightly do
        before do
          order.completed = true

          @schedule_rule = new_recurring_schedule
          order.schedule_rule = @schedule_rule

          order.save
        end

        specify { expect(order.schedule_rule).not_to be_nil }
        specify { expect(order.schedule_rule.next_occurrence).not_to be_nil }
        specify { expect(order.schedule_rule.deliver_on).to eq @schedule_rule.deliver_on }
        specify { order.schedule_rule.next_occurrence == @schedule_rule.next_occurrence }
      end
    end

    describe '#deactivate_finished' do
      before do
        allow_any_instance_of(Order).to receive(:delivery_service_includes_schedule_rule).and_return(true)

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

        rule_schedule = Fabricate(:schedule_rule, start: Date.current - 2.months, recur: nil)
        @order6 = Fabricate(:order, schedule_rule: rule_schedule)
      end

      specify { expect { Order.deactivate_finished }.to change(Order.active, :count).by(-2) }

      it 'should deactivate the correct orders' do
        Order.deactivate_finished

        expect(@order1.reload.active).to be true
        expect(@order2.reload.active).to be true
        expect(@order3.reload.active).to be true
        expect(@order4.reload.active).to be true
        expect(@order5.reload.active).to be false
        expect(@order6.reload.active).to be false
      end
    end

    describe "#future_deliveries" do
      before(:each) do
        @order = Fabricate(:active_recurring_order)
        @end_date = 4.weeks.from_now(1.day.ago).to_date
        @results = @order.future_deliveries(@end_date)
      end

      it "returns a hash with date, price and description" do
        hash = @results.first
        expect(hash[:date]).to be >= Date.current
      end

      it "includes deliveries within date range" do
        expect(@results.last[:date]).to be <= @end_date.to_date
      end
    end
  end

  context 'order requests' do
    before do
      allow_any_instance_of(Box).to receive(:likes?).and_return(true)
      allow_any_instance_of(Box).to receive(:dislikes?).and_return(true)
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

          order.excluded_line_item_ids = [@e1_id, @e4_id]
          order.save
        end

        specify { expect(order.exclusions.map(&:line_item_id)).to eq [@e1_id, @e4_id] }
      end

      context 'remove exlusions' do
        before do
          order.excluded_line_item_ids = nil
          order.save
        end

        specify { expect(order.exclusions.map(&:line_item_ids)).to eq [] }
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

          order.substituted_line_item_ids = [@s1_id, @s4_id]
          order.save
        end

        specify { expect(order.substitutions.map(&:line_item_id)).to eq [@s1_id, @s4_id] }
      end

      context 'remove substitutions' do
        before do
          order.substituted_line_item_ids = nil
          order.save
        end

        specify { expect(order.substitutions.map(&:line_item_ids)).to eq [] }
      end
    end
  end

  context "with extras" do
    before do
      @distributor = Fabricate(:distributor)
      @extras = 2.times.collect { Fabricate(:extra, distributor: @distributor) }
      @extra_ids = @extras.collect(&:id)

      @order_extras = { @extra_ids.first.to_s => { count: 3 },
                        @extra_ids.last.to_s => { count: 1 } }

      @box = Fabricate(:box, extras_limit: 5, distributor: @distributor)

      @params = Fabricate.attributes_for(:order)
      @params.merge!(box_id: @box.id, order_extras: @order_extras, schedule_rule_attributes: Fabricate.attributes_for(:schedule_rule_weekly))
      @params.except!(:schedule_rule_id)
    end

    it "should create order_extras from extra_ids" do
      order = Order.create(@params)
      expect(order).to be_valid
      expect(order.order_extras.collect(&:extra_id).sort).to eq(@extra_ids.sort)

      expect(order.extras_count).to eq(4)
      expect(order.order_extras.find_by_extra_id(@extra_ids.first).count).to eq(3)
      expect(order.order_extras.find_by_extra_id(@extra_ids.last).count).to eq(1)
    end

    it "should validate extras limit" do
      Box.find(@params[:box_id]).update_attribute(:extras_limit, 3)

      order = Order.create(@params)
      expect(order).not_to be_valid
      expect(order.errors[:base]).to include("There is more than 3 extras for this box")
    end

    it "should update extras and delete old ones" do
      order = Order.create(@params)
      expect(order).to be_valid

      @order_extras[@extra_ids.first.to_s][:count] = 0
      new_extra = Fabricate(:extra, distributor: @distributor)
      @order_extras.merge!(new_extra.id => { count: 2 })

      order.update_attributes(order_extras: @order_extras)
      expect(order).to be_valid

      expect(order.order_extras.collect(&:extra_id)).not_to include(@extra_ids.first)
      expect(order.extras_count).to eq(3)
    end

    context "predicted_order_extras" do
      it "should not return extras if they don't recur and an order occurs before this one" do
        order = Order.create(@params.merge(extras_one_off: true))
        expect(order.predicted_order_extras.size).to eq(2)
        expect(order.predicted_order_extras(order.next_occurrences(2, Date.current)[1]).size).to eq(2)
      end

      it "should return extras if they don't recur and an order doesn't occur before this one" do
        order = Order.create(@params.merge(extras_one_off: true, "schedule_rule_attributes" => { "start" => Date.current + 1.week }))
        expect(order.predicted_order_extras.size).to eq(2)
        expect(order.predicted_order_extras(order.next_occurrence - 1.day).size).to eq(2)
      end

      it "should return extras if extras recur" do
        order = Order.create(@params)
        expect(order.predicted_order_extras.size).to eq(2)
        expect(order.predicted_order_extras(order.next_occurrences(2, Date.current)[1]).size).to eq(2)
      end
    end
  end
end
