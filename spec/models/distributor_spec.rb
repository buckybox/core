require 'spec_helper'

describe Distributor do
  context :initialize do
    before { @distributor = Fabricate(:distributor, :email => ' BuckyBox@example.com ') }

    specify { @distributor.should be_valid }
    specify { @distributor.parameter_name.should == @distributor.name.parameterize }
    specify { @distributor.email.should == 'buckybox@example.com' }
  end

  context 'support email' do
    specify { Fabricate(:distributor, email: 'buckybox@example.com').support_email.should == 'buckybox@example.com' }
    specify { Fabricate(:distributor, support_email: 'support@example.com').support_email.should == 'support@example.com' }
  end

  context 'daily automation' do
    context 'default times' do
      before do
        time_now = Time.new
        Time.stub(:new).and_return(time_now)

        @build_lists_time = Time.new.beginning_of_day
        @delivery_time    = Time.new.end_of_day

        @distributor = Fabricate.build(:distributor)
        @distributor.generate_daily_lists_schedule
        @distributor.generate_auto_delivery_schedule
        @distributor.save
      end

      specify { @distributor.daily_lists_schedule.start_time == @build_lists_time }
      specify { @distributor.daily_lists_schedule.to_s == 'Daily' }
      specify { @distributor.daily_lists_schedule.next_occurrence == (@build_lists_time + 1.day) }
      specify { @distributor.auto_delivery_schedule.start_time == @delivery_time }
      specify { @distributor.auto_delivery_schedule.to_s == 'Daily' }
      specify { @distributor.auto_delivery_schedule.next_occurrence == (@delivery_time + 1.day) }
    end

    context 'custom times' do
      before do
        time_now = Time.new
        Time.stub(:new).and_return(time_now)

        @build_lists_time = Time.new.beginning_of_day + 6.hours + 32.minutes
        @delivery_time    = Time.new.beginning_of_day + 18.hours + 49.minutes

        @distributor = Fabricate.build(:distributor)
        @distributor.generate_daily_lists_schedule(@build_lists_time)
        @distributor.generate_auto_delivery_schedule(@delivery_time)
        @distributor.save

        @build_lists_time = Time.new.beginning_of_day + 6.hours
        @delivery_time    = Time.new.beginning_of_day + 18.hours
      end

      specify { @distributor.daily_lists_schedule.start_time == @build_lists_time }
      specify { @distributor.daily_lists_schedule.to_s == 'Daily' }
      specify { @distributor.daily_lists_schedule.next_occurrence == (@build_lists_time + 1.day) }
      specify { @distributor.auto_delivery_schedule.start_time == @delivery_time }
      specify { @distributor.auto_delivery_schedule.to_s == 'Daily' }
      specify { @distributor.auto_delivery_schedule.next_occurrence == (@delivery_time + 1.day) }
    end
  end

  context '#create_aily_lists' do
    before do
      @date = Date.current
      @distributor = Fabricate(:distributor)
    end

    context 'does not have daily lists' do
      specify { expect { @distributor.create_daily_lists(@date) }.should change(PackingList, :count).by(1) }
      specify { expect { @distributor.create_daily_lists(@date) }.should change(DeliveryList, :count).by(1) }
    end

    context 'already has daily lists' do
      before { @distributor.create_daily_lists(@date) }

      specify { expect { @distributor.create_daily_lists(@date) }.should_not change(PackingList, :count) }
      specify { expect { @distributor.create_daily_lists(@date) }.should_not change(DeliveryList, :count) }
    end
  end

  context '#automate_completed_status' do
    before do
      @date = Date.current + 1.week # just so it if further ahead than the scheudle start date
      @distributor = Fabricate(:distributor)
    end

    context 'does not have daily lists' do
      specify { expect { @distributor.automate_completed_status(@date) }.should change(PackingList, :count).by(1) }
      specify { expect { @distributor.automate_completed_status(@date) }.should change(DeliveryList, :count).by(1) }
    end

    context 'already has daily lists' do
      before { @distributor.create_daily_lists(@date) }

      specify { expect { @distributor.automate_completed_status(@date) }.should_not change(PackingList, :count) }
      specify { expect { @distributor.automate_completed_status(@date) }.should_not change(DeliveryList, :count) }
    end

    context 'changing the statuses' do
      before do
        box = Fabricate(:box, distributor: @distributor)
        3.times { Fabricate(:recurring_order, active: true, box: box) }
        @distributor.automate_completed_status(@date)

        @packing_list  = @distributor.packing_lists.find_by_date(@date)
        @delivery_list = @distributor.delivery_lists.find_by_date(@date)
      end

      specify { @packing_list.packages[0].status.should == 'packed' }
      specify { @packing_list.packages[0].packing_method.should == 'auto' }
      specify { @packing_list.packages[1].status.should == 'packed' }
      specify { @packing_list.packages[1].packing_method.should == 'auto' }
      specify { @packing_list.packages[2].status.should == 'packed' }
      specify { @packing_list.packages[2].packing_method.should == 'auto' }

      specify { @delivery_list.deliveries[0].status.should == 'delivered' }
      specify { @delivery_list.deliveries[0].status_change_type.should == 'auto' }
      specify { @delivery_list.deliveries[1].status.should == 'delivered' }
      specify { @delivery_list.deliveries[1].status_change_type.should == 'auto' }
      specify { @delivery_list.deliveries[2].status.should == 'delivered' }
      specify { @delivery_list.deliveries[2].status_change_type.should == 'auto' }
    end
  end
end
