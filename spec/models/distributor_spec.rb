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
    specify { distributor.customer_can_remove_orders.should be_true }

    context 'after validation' do
      before do
        distributor.email = ' BuckyBox@example.com '
        distributor.name = 'This is a Distributor!'
        distributor.valid?
      end

      specify { distributor.email.should == 'buckybox@example.com' }
    end
  end

  describe "#send_welcome_email" do
    it "sends the welcome email upon creation" do
      DistributorMailer.should_receive(:welcome) { double(deliver: nil) }

      Fabricate(:distributor)
    end
  end

  describe "#email_from" do
    it "returns the expected sender" do
      distributor = Fabricate.build(:distributor,
        name: "Garden City 2.0: FoodBag Delivery",
        support_email: "support@example.net"
      )

      distributor.email_from.should eq "Garden City 2.0 FoodBag Delivery <support@example.net>"
    end
  end

  describe "#email_to" do
    it "returns the expected recipient" do
      distributor = Fabricate.build(:distributor,
        contact_name: "Nelle",
        email: "contact@example.net"
      )

      distributor.email_to.should eq "Nelle <contact@example.net>"
    end
  end

  describe "#banks" do
    it "returns the bank names from omni importers" do
      omni_importers = [
        Fabricate.build(:omni_importer_for_bank_deposit,
          name: "Westpac - mm/dd/yyyy",
          bank_name: "Westpac"
        ),
        Fabricate.build(:omni_importer_for_bank_deposit,
          name: "Westpac - dd/mm/yyyy",
          bank_name: "Westpac"
        ),
        Fabricate.build(:omni_importer_for_bank_deposit,
          name: "Kiwibank",
          bank_name: "Kiwibank"
        ),
        Fabricate.build(:omni_importer_for_bank_deposit,
          name: "PayPal",
          bank_name: "PayPal"
        ),
      ]

      distributor = Fabricate(:distributor, omni_importers: omni_importers)

      expect(distributor.banks).to match_array %w(Westpac Kiwibank PayPal)
    end
  end

  context 'parameter name' do
    context 'when creating a new distributor' do
      before do
        distributor.name = 'New Distributor'
        distributor.save
      end

      specify { distributor.parameter_name.should == 'new-distributor' }

      context "and an invalid parameter name is set" do
        before do
          distributor.name = 'New Distributor'
          distributor.parameter_name = "invalid/name/@)*&"
        end

        specify { distributor.should_not be_valid }
      end
    end

    context 'when updating an existing distributor' do
      before { distributor.name = 'Saved Distributor' }

      context 'and there is no existing parameter name' do
        describe 'it will default from name' do
          before { distributor.save }
          specify { distributor.parameter_name.should == 'saved-distributor' }
        end

        describe 'it will create from value' do
          before do
            distributor.parameterize_name('Great Veggie Box Delivery!')
            distributor.save
          end

          specify { distributor.parameter_name.should == 'great-veggie-box-delivery' }
        end
      end

      context 'and there is an existing parameter name' do
        before { distributor.parameter_name = 'fruit-by-the-bucket' }

        describe 'it will not use parameterized name' do
          before { distributor.save }
          specify { distributor.parameter_name.should == 'fruit-by-the-bucket' }
        end

        describe 'it will create from value' do
          before do
            distributor.parameterize_name('Great Veggie Box Delivery!')
            distributor.save
          end

          specify { distributor.parameter_name.should == 'great-veggie-box-delivery' }
        end
      end
    end
  end

  context 'delivery window parameters' do
    specify { Fabricate.build(:distributor, advance_hour: -1).should_not be_valid }
    specify { Fabricate.build(:distributor, advance_days: -1).should_not be_valid }
    specify { Fabricate.build(:distributor, automatic_delivery_hour: -1).should_not be_valid }
  end

  context 'support email' do
    specify { Fabricate(:distributor, email: 'buckybox@example.com').support_email.should == 'buckybox@example.com' }
    specify { Fabricate(:distributor, support_email: 'support@example.com').support_email.should == 'support@example.com' }
  end

  describe '#generate_required_daily_lists' do
    let(:generator) { double('generator') }
    let(:generator_class) { double('generator_class', new: generator) }

    it 'returns true if the daily list generator successfully performs the generation' do
      generator.stub(:generate) { true }
      distributor.generate_required_daily_lists(generator_class).should be_true
    end

    it 'returns false if the daily list generator fails to performs the generation' do
      generator.stub(:generate) { true }
      distributor.generate_required_daily_lists(generator_class).should be_true
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
      before do
        #FIXME See below reason for pending tests
        pending 'These two tests fail randomly. Fix or remove soon'
      end
      specify { expect { Distributor.create_daily_lists }.to change(PackingList, :count).by(1) }
      specify { expect { Distributor.create_daily_lists }.to change(DeliveryList, :count).by(1) }
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
          time = Time.current
          time_tomorrow = Time.current + 1.day
          @today = [time.year, time.month, time.day]
          @tomorrow = [time_tomorrow.year, time_tomorrow.month, time_tomorrow.day]
          @schedule_start = [Distributor::DEFAULT_ADVANCED_HOURS, 0]
          @schedule_end = [Distributor::DEFAULT_ADVANCED_HOURS - 1, 1]

          Delorean.time_travel_to Time.zone.local(*(@today))

          @d_welly = Fabricate(:distributor, time_zone: 'Wellington')
          @d_perth = Fabricate(:distributor, time_zone: 'Perth')
          @d_london = Fabricate(:distributor, time_zone: 'London')

          @d_welly_d_list = Fabricate(:delivery_list, distributor: @d_welly, date: Date.yesterday)

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

    context '.find_extra_from_import' do
      before do
        search_extras = [
          [:oj600, 'Orange Juice',  '600 ml'   ],
          [:oj650, 'Orange Juice',  '650 ml'   ],
          [:oj1,   'Orange Juice',  '1L'       ],
          [:os800, 'Organic Sugar', '800 g'    ],
          [:os15,  'Organic Sugar', '1.5 kg'   ],
          [:e6,    'Eggs',          '1 / 2 Doz'],
          [:e12,   'Eggs',          'Doz'      ]
        ]
        @s = {}

        search_extras.map! { |sym, name, unit| @s.merge!(sym => Fabricate.build(:extra, { name: name, unit:unit }))[sym] }

        @distributor = Fabricate.build(:distributor)
        @distributor.stub_chain(:extras, :alphabetically).and_return(search_extras)
        @box = mock_model(Box)
        @box.stub_chain(:extras, :alphabeticaly).and_return(search_extras)
      end

      EXTRAS_IMPORT_TESTS = [
        ['Orange Juice',   '1L',      :oj1  ],
        ['Oronge juice',   '1L',      :oj1  ],
        ['Orang uice',     '1L',      :oj1  ],
        ['Orange Juice',   '1 L',     :oj1  ],
        ['Orange Juice',   '1',       :oj1  ],
        ['Orange Juice',   '600',     :oj600],
        ['Orange Juice',   '60',      :oj600],
        ['Orange Juice',   '6',       :oj600],
        ['Egg',            'Doz',     :e12  ],
        ['Eggs',           '1/2 Doz', :e6   ],
        ['organic suga',   '',        :os15 ],
        ['orgaanic sugar', '800g',    :os800],
        ['o juice',        '600 ml',  :nil  ],
        ['not in list',    '',        :nil  ],
        ['sugar juice',    '',        :nil  ]
      ]

      EXTRAS_IMPORT_TESTS.each do |name, unit, match|
        specify { @distributor.find_extra_from_import(double('Extra', { name: name, unit: unit })).should eq(@s[match]) }
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

  describe ".find_duplicate_import_transactions" do
    it "should find duplicate import transactions" do
      distributor.stub_chain(:import_transactions, :processed, :not_duplicate, :not_removed, :where).with({transaction_date: Date.parse("12 Oct 2011"), description: "hello kitty here is payment", amount_cents: 23465})

      distributor.find_duplicate_import_transactions(Date.parse("12 Oct 2011"), "hello kitty here is payment", 234.65)
    end
  end

  describe :balance_thresholds do
    let(:distributor) { Fabricate(:distributor_a_customer) }

    it 'should update all customers spend limit' do 
      Customer.any_instance.should_receive(:update_halted_status!).with(nil, Customer::EmailRule.only_pending_orders)
      distributor.update_attributes({has_balance_threshold: true, default_balance_threshold: 200.00, spend_limit_on_all_customers: '0'}).should be_true
    end
  end

  describe ".update_next_occurrence_caches" do
    let(:customer){
      distributor.save!
      Fabricate(:customer, distributor: distributor)
    }
    let(:order){Fabricate(:order, account: customer.account)}
    it 'updates cached value of next order' do
      order
      customer.update_column(:next_order_occurrence_date, nil)
      customer.update_column(:next_order_id, nil)
      customer.reload
      customer.next_order_occurrence_date.should eq nil

      distributor.update_next_occurrence_caches

      customer.reload
      customer.next_order_occurrence_date.should eq order.next_occurrence(Time.current.hour >= distributor.automatic_delivery_hour ? Date.current.tomorrow : Date.current)
    end
  end

  describe ".transactional_customer_count" do

    let(:distributor) { Fabricate(:distributor) }
    let(:customer){ customer = Fabricate(:customer, distributor: distributor) }

    it "returns zero when no transactions on any customers" do
      customer
      distributor.transactional_customer_count.should eq 0
    end

    it "counts the number of customers with transactions" do
      Fabricate(:transaction, account: customer.account)
      Fabricate(:customer, distributor: distributor)
      Fabricate(:transaction, account: Fabricate(:account))
      distributor.transactional_customer_count.should eq 1
    end
  end

  describe "#notify_of_address_change" do
    context "notify_address_change is true" do
      let(:distributor){ Fabricate.build(:distributor, notify_address_change: true) }

      it "retruns true if successful" do
        customer = double('customer')
        notifier = double('Event', customer_changed_address: true)

        distributor.notify_address_changed(customer, notifier).should eq true
      end
    end

    context "returns false if unsuccesful" do
      it "retuns false if notify address change is false" do
        distributor.notify_address_change = false
        customer = double('customer')
        notifier = double('Event')
        distributor.notify_address_changed(customer, notifier).should eq false
      end

      it "returns false if fails" do
        customer = double('customer')
        notifier = double('Event', customer_changed_address: false)
        distributor.notify_address_changed(customer, notifier).should eq false
      end
    end
  end

  describe '#customer_for_export' do
    it 'returns customers based on customer ids' do
      distributor.save
      customer_1 = Fabricate(:customer, distributor: distributor)
      customer_2 = Fabricate(:customer, distributor: distributor)
      distributor.customers_for_export([customer_1.id]).should eq([customer_1])
    end
  end

  context "Communications and tracking" do
    subject { distributor }
    it { should delegate(:tracking_after_create).to(:tracking) }
    it { should delegate(:tracking_after_save).to(:tracking) }
    it { should delegate(:track).to(:tracking) }
  end

  describe '#transactions_for_export' do
    let(:day1)    { Date.parse('2013-08-03') }
    let(:day2)    { Date.parse('2013-08-04') }
    let(:day3)    { Date.parse('2013-08-05') }

    before do
      @pay1   = Fabricate(:transaction, display_time: day1)
      account = @pay1.account
      @dist    = account.distributor
      @pay2   = Fabricate(:transaction, display_time: day2, account: account)
      @pay3   = Fabricate(:transaction, display_time: day3, account: account)
    end

    it "returns 3 transactions" do
      from   = Date.parse('2013-08-02')
      to     = Date.parse('2013-08-06')
      result = @dist.transactions_for_export(from, to)
      expect(result).to eq([@pay3, @pay2, @pay1])
    end

    it "returns 2 transactions" do
      from   = day1
      to     = day3
      result = @dist.transactions_for_export(from, to)
      expect(result).to eq([@pay2, @pay1])
    end

    it "returns 1 transactions" do
      from   = day1
      to     = day2
      result = @dist.transactions_for_export(from, to)
      expect(result).to eq([@pay1])
    end

    it "returns 0 transactions" do
      from   = day2
      to     = day2
      result = @dist.transactions_for_export(from, to)
      expect(result).to be_empty
    end
  end
end
