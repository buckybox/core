require 'spec_helper'

describe Order do
  before { @order = Fabricate(:order) }

  specify { @order.should be_valid }

  context :quantity do
    specify { Fabricate.build(:order, :quantity => 0).should_not be_valid }
    specify { Fabricate.build(:order, :quantity => -1).should_not be_valid }
  end

  context :frequency do
    %w(single weekly fortnightly).each do |f|
      specify { Fabricate.build(:order, :frequency => f).should be_valid }
    end

    specify { Fabricate.build(:order, :frequency => 'yearly').should_not be_valid }
  end

  context :schedule do
    before do
      @route = Fabricate(:route, :distributor => @order.distributor)
      @order.completed = true
    end

    context :single do
      before do
        @order.frequency = 'single'
        @order.save
      end

      specify { @order.schedule.to_s.should == @route.next_run.strftime("%B %e, %Y") }
      specify { @order.schedule.next_occurrence == @route.next_run }
      specify { @order.should have(1).delivery }
    end

    context :weekly do
      before do
        @order.frequency = 'weekly'
        @order.save
      end

      specify { @order.schedule.to_s.should == 'Weekly' }
      specify { @order.schedule.next_occurrence == @route.next_run }
      specify { @order.should have(1).delivery }
    end

    context :fortnightly do
      before do
        @order.frequency = 'fortnightly'
        @order.save
      end

      specify { @order.schedule.to_s.should == 'Every 2 weeks' }
      specify { @order.schedule.next_occurrence == @route.next_run }
      specify { @order.should have(1).delivery }
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

  describe '#create_next_delivery' do
    before do
      Fabricate(:route, :distributor => @order.distributor)
      @order.save
    end

    context "when order has not been completed" do
      specify { expect { @order.create_next_delivery }.should_not change(Delivery, :count) }
    end

    context "when order is inactive" do
      before { @order.active = true }
      specify { expect { @order.create_next_delivery }.should_not change(Delivery, :count) }
    end

    context "when order has been completed" do
      before { @order.completed = true }
      specify { expect { @order.create_next_delivery }.should change(Delivery, :count).by(1) }
    end

    context "when delivery already exists" do
      before { @order.create_next_delivery }
      specify { expect { @order.create_next_delivery }.should_not change(Delivery, :count) }
    end
  end

  describe '#create_next_delivery' do
    before do
      box = Fabricate(:box, :distributor => Fabricate(:route).distributor)
      3.times { Fabricate(:order, :box => box, :completed => true, :frequency => 'weekly') }
      Fabricate(:order, :box => box, :frequency => 'weekly')
      Fabricate(:order, :box => box, :frequency => 'weekly', :active => false)
    end

    it "should create the next delivery for each active order if it doesn't exist already" do
      Delorean.time_travel_to('1 month from now') do
        expect { Order.create_next_delivery }.should change(Delivery, :count).by(3)
      end
    end
  end
end

