require 'spec_helper'

describe Distributor do
  let(:distributor) { Fabricate.build(:distributor) }

  context :initialize do
    specify { distributor.should be_valid }
    specify { distributor.time_zone.should == 'Wellington' }
    specify { distributor.currency.should == 'nzd' }
    specify { distributor.advance_hour.should == 18 }
    specify { distributor.advance_days.should == 3 }
    specify { distributor.automatic_delivery_hour.should == 18 }

    context 'after validation' do
      before do
        distributor.email = ' BuckyBox@example.com '
        distributor.name = 'This is a Distributor!'
        distributor.valid?
      end

      specify { distributor.parameter_name.should == 'this-is-a-distributor' }
      specify { distributor.email.should == 'buckybox@example.com' }
    end
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
        @current_time = Time.zone.local(2012, 3, 20, Distributor::DEFAULT_AUTOMATIC_DELIVERY_HOUR - 1)
        @default_days = Distributor::DEFAULT_ADVANCED_DAYS
        Delorean.time_travel_to(@current_time)
      end

      context 'new distributor' do
        it 'the generated packing lists should start from today' do
          distributor.save
          distributor.packing_lists.first.date.should == Date.current
        end

        specify { expect { distributor.save }.should change(PackingList, :count).from(0).to(@default_days) }
        specify { expect { distributor.save }.should change(DeliveryList, :count).from(0).to(@default_days) }
      end

      context 'distributor changes advance days' do
        context 'make a bigger window' do
          before do
            distributor.save
            @custom_days = @default_days + 2
            distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from today' do
            distributor.save
            distributor.packing_lists.first.date.should == Date.today
          end

          specify { expect { distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end

        context 'make a smaller window' do
          before do
            distributor.save
            @custom_days = @default_days - 2
            distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from today' do
            distributor.save
            distributor.packing_lists.first.date.should == Date.today
          end

          specify { expect { distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end
      end
    end

    context 'current time after advance_hour' do
      before do
        @current_time = Time.zone.local(2012, 3, 20, Distributor::DEFAULT_AUTOMATIC_DELIVERY_HOUR + 1)
        @default_days = Distributor::DEFAULT_ADVANCED_DAYS
        Delorean.time_travel_to(@current_time)
      end

      context 'new distributor' do
        it 'the generated packing lists should start from tomorrow' do
          distributor.save
          distributor.packing_lists.first.date.should == Date.tomorrow
        end

        specify { expect { distributor.save }.should change(PackingList, :count).from(0).to(@default_days) }
        specify { expect { distributor.save }.should change(DeliveryList, :count).from(0).to(@default_days) }
      end

      context 'distributor changes advance days' do
        context 'make a bigger window' do
          before do
            distributor.save
            @custom_days = @default_days + 2
            distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from tomorrow' do
            distributor.save
            distributor.packing_lists.first.date.should == Date.tomorrow
          end

          specify { expect { distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end

        context 'make a smaller window' do
          before do
            distributor.save
            @custom_days = @default_days - 2
            distributor.advance_days = @custom_days
          end

          it 'the generated packing lists should start from tomorrow' do
            distributor.save
            distributor.packing_lists.first.date.should == Date.tomorrow
          end

          specify { expect { distributor.save }.should change(PackingList, :count).from(@default_days).to(@custom_days) }
          specify { expect { distributor.save }.should change(DeliveryList, :count).from(@default_days).to(@custom_days) }
        end
      end
    end
  end

  context 'cron related methods' do
    before do
      @current_time = Time.zone.local(2012, 3, 20, Distributor::DEFAULT_ADVANCED_HOURS)
      Delorean.time_travel_to(@current_time)

      @distributor1 = Fabricate(:distributor, advance_hour: 18, advance_days: 3, automatic_delivery_hour: 18)
      daily_orders(@distributor1)

      @current_time = @current_time + 1.day
      Delorean.time_travel_to(@current_time)

      @distributor2 = Fabricate(:distributor, advance_hour: 12, advance_days: 4, automatic_delivery_hour: 22)
      daily_orders(@distributor2)

      @distributor3 = Fabricate(:distributor, advance_hour: 0, advance_days: 7, automatic_delivery_hour: 24)
      daily_orders(@distributor3)
    end

    after { Delorean.back_to_the_present }

    context '@distributor1 should generate daily lists' do
      specify { expect { Distributor.create_daily_lists }.should change(PackingList, :count).by(1) }
      specify { expect { Distributor.create_daily_lists }.should change(DeliveryList, :count).by(1) }
    end
  end

  context 'time zone' do
    before { Time.zone = 'Paris' }

    describe '.change_to_local_time_zone' do
      context 'with no time_zone settings' do
        before do
          distributor = Fabricate(:distributor, time_zone: '')
          distributor.change_to_local_time_zone
        end

        specify { Time.zone.name.should eq 'Wellington' }
      end

      context 'with time_zone set to Berlin' do
        before do
          distributor = Fabricate(:distributor, time_zone: 'Berlin')
          distributor.change_to_local_time_zone
        end

        specify { Time.zone.name.should eq 'Berlin' }
      end
    end

    describe '.use_local_time_zone' do
      context 'with no time_zone settings' do
        before { @distributor = Fabricate(:distributor, time_zone: '') }

        it 'should temporarily change Time.now' do
          @distributor.use_local_time_zone { Time.zone.name.should eq('Wellington') }
          Time.zone.name.should eq('Paris')
        end
      end

      context 'with time_zone set to Berlin' do
        before { @distributor = Fabricate(:distributor, time_zone: 'Berlin') }

        it 'should temporarily change Time.now' do
          @distributor.use_local_time_zone { Time.zone.name.should eq('Berlin') }
          Time.zone.name.should eq('Paris')
        end
      end
    end

    context 'daily automation' do
      context 'time zone set to Wellington' do
        before do
          Time.zone = 'Wellington'
          @today = [Time.current.year, Time.current.month, Time.current.day]
          @tomorrow = [Time.current.year, Time.current.month, Time.current.day + 1]
          @schedule_start = [Distributor::DEFAULT_ADVANCED_HOURS, 0]
          @schedule_end = [Distributor::DEFAULT_ADVANCED_HOURS - 1, 1]

          Delorean.time_travel_to Time.zone.local(*(@today))

          @d_welly = Fabricate(:distributor, time_zone: 'Wellington')
          @d_perth = Fabricate(:distributor, time_zone: 'Perth')
          @d_london = Fabricate(:distributor, time_zone: 'London')

          @d_welly_d_list = Fabricate(:delivery_list_with_associations, distributor: @d_welly, date: Date.yesterday)

          Fabricate(:delivery, delivery_list: @d_welly_d_list)
        end

        after { Delorean.back_to_the_present }

        context 'time set to Wellington start of day' do
          before { Delorean.time_travel_to(Time.zone.local(*(@tomorrow + @schedule_start))) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 2 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to Wellington end of day' do
          before { Delorean.time_travel_to(Time.zone.local(*(@tomorrow + @schedule_end))) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to Perth start of day' do
          before { Delorean.time_travel_to(Time.use_zone('Perth'){ Time.zone.local(*(@tomorrow + @schedule_start)) }.in_time_zone('Wellington') ) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 2 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to Perth end of day' do
          before { Delorean.time_travel_to(Time.use_zone('Perth'){ Time.zone.local(*(@tomorrow + @schedule_end)) }.in_time_zone('Wellington') ) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to London start of day' do
          before { Delorean.time_travel_to(Time.use_zone('London'){ Time.zone.local(*(@tomorrow + @schedule_start)) }.in_time_zone('Wellington') ) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 2 }
        end

        context 'time set to London end of day' do
          before { Delorean.time_travel_to(Time.use_zone('London'){ Time.zone.local(*(@tomorrow + @schedule_end)) }.in_time_zone('Wellington') ) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end
      end
    end
  end

  context '.import_customers' do
    specify { expect { distributor.import_customers([]) }.to raise_error('No customers') }
    specify { expect { distributor.import_customers([123, 456, 789]) }.to raise_error('Expecting Bucky::Import::Customer but was Fixnum') }

    it 'calls import on each customer' do
      route = mock_model(Route)
      import_customers = []

      2.times do |n|
        customer = double('Customer')
        customer.stub(:import)

        import_customer = new_import_customer(n)
        distributor.stub_chain(:routes, :find_by_name).and_return(route)
        distributor.stub_chain(:customers, :find_by_number).with(n).and_return(customer)

        customer.should_receive(:import).with(import_customer, route)
        import_customers << import_customer
      end

      distributor.import_customers(import_customers)
    end

    it 'raises error if can not find route' do
      import_customer = new_import_customer
      distributor.stub_chain(:routes, :find_by_name).and_return(nil)
      distributor.stub_chain(:customers, :find_by_number).and_return(double('Customer'))

      expect { distributor.import_customers([import_customer]) }.to raise_error('Route  not found for distributor with id ' )
    end

    context ".find_extra_from_import" do
      before do
        search_extras = [
          [:oj600, "Orange Juice",  "600 ml"   ],
          [:oj650, "Orange Juice",  "650 ml"   ],
          [:oj1,   "Orange Juice",  "1L"       ],
          [:os800, "Organic Sugar", "800 g"    ],
          [:os15,  "Organic Sugar", "1.5 kg"   ],
          [:e6,    "Eggs",          "1 / 2 Doz"],
          [:e12,   "Eggs",          "Doz"      ]
        ]
        @s = {}

        search_extras.map! { |sym, name, unit| @s.merge!(sym => Fabricate.build(:extra, { name: name, unit:unit }))[sym] }

        @distributor = Fabricate.build(:distributor)
        @distributor.stub_chain(:extras, :alphabetically).and_return(search_extras)
        @box = mock_model(Box)
        @box.stub_chain(:extras, :alphabeticaly).and_return(search_extras)
      end

      EXTRAS_IMPORT_TESTS = [
        ["Orange Juice",   "1L",      :oj1  ],
        ["Oronge juice",   "1L",      :oj1  ],
        ["Orang uice",     "1L",      :oj1  ],
        ["Orange Juice",   "1 L",     :oj1  ],
        ["Orange Juice",   "1",       :oj1  ],
        ["Orange Juice",   "600",     :oj600],
        ["Orange Juice",   "60",      :oj600],
        ["Orange Juice",   "6",       :oj600],
        ["Egg",            "Doz",     :e12  ],
        ["Eggs",           "1/2 Doz", :e6   ],
        ["organic suga",   "",        :os15 ],
        ["orgaanic sugar", "800g",    :os800],
        ["o juice",        "600 ml",  :nil  ],
        ["not in list",    "",        :nil  ],
        ["sugar juice",    "",        :nil  ]
      ]

      EXTRAS_IMPORT_TESTS.each do |name, unit, match|
        specify { @distributor.find_extra_from_import(mock('Extra', {name: name, unit: unit})).should eq(@s[match]) }
      end
    end
  end

  def new_import_customer(number = 1)
    import_customer = double('Bucky::Import::Customer')

    import_customer.stub(:class).and_return(Bucky::Import::Customer)
    import_customer.stub(:number).and_return(number)
    import_customer.stub(:delivery_route)

    return import_customer
  end
end
