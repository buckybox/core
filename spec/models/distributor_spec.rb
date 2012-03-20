require 'spec_helper'

describe Distributor do
  context :initialize do
    before(:all) { @distributor = Fabricate(:distributor, :email => ' BuckyBox@example.com ') }

    specify { @distributor.should be_valid }
    specify { @distributor.parameter_name.should == @distributor.name.parameterize }
    specify { @distributor.email.should == 'buckybox@example.com' }
    specify { @distributor.advance_hour.should == 18 }
    specify { @distributor.advance_days.should == 3 }
    specify { @distributor.automatic_delivery_hour.should == 18 }
  end

  context 'delivery window parameters' do
    specify { Fabricate.build(:distributor, advance_hour: -1).should_not be_valid }
    specify { Fabricate.build(:distributor, advance_days: 0).should_not be_valid }
    specify { Fabricate.build(:distributor, automatic_delivery_hour: -1).should_not be_valid }
  end

  context 'support email' do
    specify { Fabricate(:distributor, email: 'buckybox@example.com').support_email.should == 'buckybox@example.com' }
    specify { Fabricate(:distributor, support_email: 'support@example.com').support_email.should == 'support@example.com' }
  end

  context '#generate_required_daily_lists' do
    after { Delorean.back_to_the_present }

    context 'current time before advance_hour' do
      before do
        @current_time = Time.new(2012, 3, 20, Distributor::DEFAULT_AUTOMATIC_DELIVERY_HOUR - 1)
        @default_days = Distributor::DEFAULT_ADVANCED_DAYS
        Delorean.time_travel_to(@current_time)
      end

      context 'new distributor' do
        before { @distributor = Fabricate.build(:distributor) }

        it 'the generated packing lists should start from today' do
          @distributor.save
          @distributor.packing_lists.first.date.should == Date.today
        end

        specify { expect { @distributor.save }.should change(PackingList, :count).from(0).to(@default_days) }
        specify { expect { @distributor.save }.should change(DeliveryList, :count).from(0).to(@default_days) }
      end

      context 'distributor changes advance days' do
        before do
          @distributor = Fabricate(:distributor)
        end

        context 'make a bigger window' do
          before do
            @custom_days = @default_days + 2
            @distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from today' do
            @distributor.save
            @distributor.packing_lists.first.date.should == Date.today
          end

          specify { expect { @distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { @distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end

        context 'make a smaller window' do
          before do
            @custom_days = @default_days - 2
            @distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from today' do
            @distributor.save
            @distributor.packing_lists.first.date.should == Date.today
          end

          specify { expect { @distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { @distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end
      end
    end

    context 'current time after advance_hour' do
      before do
        @current_time = Time.new(2012, 3, 20, Distributor::DEFAULT_AUTOMATIC_DELIVERY_HOUR + 1)
        @default_days = Distributor::DEFAULT_ADVANCED_DAYS
        Delorean.time_travel_to(@current_time)
      end

      context 'new distributor' do
        before { @distributor = Fabricate.build(:distributor) }

        it 'the generated packing lists should start from tomorrow' do
          @distributor.save
          @distributor.packing_lists.first.date.should == Date.tomorrow
        end

        specify { expect { @distributor.save }.should change(PackingList, :count).from(0).to(@default_days) }
        specify { expect { @distributor.save }.should change(DeliveryList, :count).from(0).to(@default_days) }
      end

      context 'distributor changes advance days' do
        before { @distributor = Fabricate(:distributor) }

        context 'make a bigger window' do
          before do
            @custom_days = @default_days + 2
            @distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from tomorrow' do
            @distributor.save
            @distributor.packing_lists.first.date.should == Date.tomorrow
          end

          specify { expect { @distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { @distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end

        context 'make a smaller window' do
          before do
            @custom_days = @default_days - 2
            @distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from tomorrow' do
            @distributor.save
            @distributor.packing_lists.first.date.should == Date.tomorrow
          end

          specify { expect { @distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { @distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end
      end
    end
  end

  context 'cron related methods' do
    before do
      @current_time = Time.new(2012, 3, 20, Distributor::DEFAULT_ADVANCED_HOURS)
      Delorean.time_travel_to(@current_time)

      @distributor = Fabricate(:distributor)
      daily_orders(@distributor)

      @current_time = @current_time + 1.day
      Delorean.time_travel_to(@current_time)
    end

    after { Delorean.back_to_the_present }

    context 'for class' do
      before do
        @distributor2 = Fabricate(:distributor, advance_hour: 12, advance_days: 4, automatic_delivery_hour: 22)
        daily_orders(@distributor2)

        @distributor3 = Fabricate(:distributor, advance_hour: 0, advance_days: 7, automatic_delivery_hour: 24)
        daily_orders(@distributor3)
      end

      context '.create_daily_lists' do
        context '@distributor should generate daily lists' do
          specify { expect { Distributor.create_daily_lists }.should change(PackingList, :count).by(1) }
          specify { expect { Distributor.create_daily_lists }.should change(DeliveryList, :count).by(1) }
        end
      end

      context '.automate_completed_status' do
      end
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
          @d_welly.save

          @d_perth = Fabricate.build(:distributor, time_zone: 'Perth')
          @d_perth.save

          @d_london = Fabricate.build(:distributor, time_zone: 'London')
          @d_london.save

          @d_welly_d_list = Fabricate(:delivery_list, distributor: @d_welly, date: Date.yesterday)
          Fabricate(:delivery, delivery_list: @d_welly_d_list)
        end

        after { Delorean.back_to_the_present }

        context 'time set to Wellington start of day' do
          # Wellington time zone beginning of day 
          before { Delorean.time_travel_to(Time.current.beginning_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 2}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Wellington end of day' do
          # Wellington time zone beginning of day
          before { Delorean.time_travel_to(Time.current.end_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours - 59.minutes) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Perth start of day' do
          before { Delorean.time_travel_to(Time.use_zone("Perth"){Time.current.beginning_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours}.in_time_zone("Wellington")) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 2}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to Perth end of day' do
          before { Delorean.time_travel_to(Time.use_zone("Perth"){Time.current.end_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours - 59.minutes}.in_time_zone("Wellington")) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end

        context 'time set to London start of day' do
          before { Delorean.time_travel_to(Time.use_zone("London"){Time.current.beginning_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours}.in_time_zone("Wellington")) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 2}
        end

        context 'time set to London end of day' do
          before { Delorean.time_travel_to(Time.use_zone("London"){Time.current.end_of_day + 1.day + Distributor::DEFAULT_ADVANCED_HOURS.hours - 59.minutes}.in_time_zone("Wellington")) }

          specify { expect{Distributor.create_daily_lists}.to change{@d_welly.packing_lists.count + @d_welly.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_perth.packing_lists.count + @d_perth.delivery_lists.count}.by 0}
          specify { expect{Distributor.create_daily_lists}.to change{@d_london.packing_lists.count + @d_london.delivery_lists.count}.by 0}
        end
      end
    end
  end

  private

  def daily_orders(distributor)
    daily_order_schedule = schedule = Schedule.new
    daily_order_schedule.add_recurrence_rule(IceCube::Rule.daily)

    3.times do
      customer = Fabricate(:customer, distributor: distributor)
      Fabricate(:active_order, account: customer.account, schedule: daily_order_schedule)
    end
  end
end
