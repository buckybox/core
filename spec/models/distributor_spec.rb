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
        time_now = Time.current
        Time.stub(:current).and_return(time_now)

        @build_lists_time = Time.current.beginning_of_day
        @delivery_time    = Time.current.end_of_day

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
        time_now = Time.current
        Time.stub(:new).and_return(time_now)

        @build_lists_time = Time.current.beginning_of_day + 6.hours + 32.minutes
        @delivery_time    = Time.current.beginning_of_day + 18.hours + 49.minutes

        @distributor = Fabricate.build(:distributor)
        @distributor.generate_daily_lists_schedule(@build_lists_time)
        @distributor.generate_auto_delivery_schedule(@delivery_time)
        @distributor.save

        @build_lists_time = Time.current.beginning_of_day + 6.hours
        @delivery_time    = Time.current.beginning_of_day + 18.hours
      end

      specify { @distributor.daily_lists_schedule.start_time == @build_lists_time }
      specify { @distributor.daily_lists_schedule.to_s == 'Daily' }
      specify { @distributor.daily_lists_schedule.next_occurrence == (@build_lists_time + 1.day) }
      specify { @distributor.auto_delivery_schedule.start_time == @delivery_time }
      specify { @distributor.auto_delivery_schedule.to_s == 'Daily' }
      specify { @distributor.auto_delivery_schedule.next_occurrence == (@delivery_time + 1.day) }
    end
  end

  context 'time zone' do
    describe '.change_to_local_time_zone' do
      context 'with no time_zone settings' do
        before do
          Time.zone = "Paris"
          @distributor = Fabricate(:distributor, time_zone: "")
          @distributor.change_to_local_time_zone
        end
        specify { Time.zone.name.should eq "Wellington" }
      end

      context 'with time_zone set to Berlin' do
        before do
          @distributor = Fabricate(:distributor, time_zone: "Berlin")
          @distributor.change_to_local_time_zone
        end
        specify { Time.zone.name.should eq "Berlin" }
      end
    end

    describe '.use_local_time_zone' do
      context 'with no time_zone settings' do
        before do
          Time.zone = "Paris"
          @distributor = Fabricate(:distributor, time_zone: "")
        end
        it 'should temporarily change Time.now' do
          @distributor.use_local_time_zone { Time.zone.name.should eq "Wellington" } 
          Time.zone.name.should eq("Paris")
        end
      end

      context 'with time_zone set to Berlin' do
        before do
          Time.zone = "Paris"
          @distributor = Fabricate(:distributor, time_zone: "Berlin")
        end
        it 'should temporarily change Time.now' do
          @distributor.use_local_time_zone { Time.zone.name.should eq "Berlin" } 
          Time.zone.name.should eq("Paris")
        end
      end
    end

    context 'daily automation' do
      context 'time zone set to Wellington' do
        before do
          Time.zone = "Wellington"
          
          @d_welly = Fabricate.build(:distributor, time_zone: 'Wellington')
          @d_welly.generate_daily_lists_schedule
          @d_welly.generate_auto_delivery_schedule
          @d_welly.save

          @d_perth = Fabricate.build(:distributor, time_zone: 'Perth')
          @d_perth.generate_daily_lists_schedule
          @d_perth.generate_auto_delivery_schedule
          @d_perth.save
          
          @d_london = Fabricate.build(:distributor, time_zone: 'London')
          @d_london.generate_daily_lists_schedule
          @d_london.generate_auto_delivery_schedule
          @d_london.save
          
          @d_welly_d_list = Fabricate(:delivery_list, distributor: @d_welly, date: Date.yesterday)
          Fabricate(:delivery, delivery_list: @d_welly_d_list)

        end
        
        context 'time set to Wellington start of day' do
          before do
            Delorean.time_travel_to(Time.current.beginning_of_day) # Wellington time zone beginning of day
          end
          after do
            Delorean.back_to_the_present
          end

          specify { @d_welly.daily_lists_schedule.start_time.zone.should eq('NZDT') }
          specify { @d_perth.daily_lists_schedule.start_time.zone.should eq('WST') }
          specify { @d_london.daily_lists_schedule.start_time.zone.should eq('GMT') }
          
          specify { @d_welly.auto_delivery_schedule.start_time.zone.should eq('NZDT') }
          specify { @d_perth.auto_delivery_schedule.start_time.zone.should eq('WST') }
          specify { @d_london.auto_delivery_schedule.start_time.zone.should eq('GMT') }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 2}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Wellington end of day' do
          before do
            Delorean.time_travel_to(Time.current.end_of_day - 59.minutes) # Wellington time zone beginning of day
          end
          after do
            Delorean.back_to_the_present
          end
          
          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Perth start of day' do
          before do
            Delorean.time_travel_to(Time.use_zone("Perth"){Time.current.beginning_of_day}.in_time_zone("Wellington"))
          end
          after do
            Delorean.back_to_the_present
          end

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 2}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Perth end of day' do
          before do
            Delorean.time_travel_to(Time.use_zone("Perth"){Time.current.end_of_day - 59.minutes}.in_time_zone("Wellington"))
          end
          after do
            Delorean.back_to_the_present
          end

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to London start of day' do
          before do
            Delorean.time_travel_to(Time.use_zone("London"){Time.current.beginning_of_day}.in_time_zone("Wellington"))
          end
          after do
            Delorean.back_to_the_present
          end

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 2}
        end

        context 'time set to London end of day' do
          before do
            Delorean.time_travel_to(Time.use_zone("London"){Time.current.end_of_day - 59.minutes}.in_time_zone("Wellington"))
          end
          after do
            Delorean.back_to_the_present
          end

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end
      end
    end
  end
end
