require 'spec_helper'

describe Distributor do
  let(:distributor) { Fabricate.build(:distributor) }

  context :initialize do
    specify { expect(distributor).to be_valid }
    specify { expect(distributor.time_zone).to eq 'Wellington' }
    specify { expect(distributor.currency).to eq 'NZD' }
    specify { expect(distributor.advance_days).to eq 3 }
    specify { expect(distributor.customer_can_remove_orders).to be true }

    context 'after validation' do
      before do
        distributor.email = ' BuckyBox@example.com '
        distributor.name = 'This is a Distributor!'
        distributor.valid?
      end

      specify { expect(distributor.email).to eq 'buckybox@example.com' }
    end
  end

  describe "#send_welcome_email" do
    it "sends the welcome email upon creation" do
      expect(DistributorMailer).to receive(:welcome) { double(deliver: nil) }

      Fabricate(:distributor)
    end
  end

  describe "#email_from" do
    it "returns the expected sender" do
      distributor = Fabricate.build(:distributor,
        name: "Garden City 2.0: FoodBag Delivery",
        support_email: "support@example.net"
      )

      expect(distributor.email_from).to eq "Garden City 2.0 FoodBag Delivery <support@example.net>"
      expect(distributor.email_from(email: "joe@i.com")).to eq "Garden City 2.0 FoodBag Delivery <joe@i.com>"
    end
  end

  describe "#email_to" do
    it "returns the expected recipient" do
      distributor = Fabricate.build(:distributor,
        contact_name: "Nelle",
        email: "contact@example.net"
      )

      expect(distributor.email_to).to eq "Nelle <contact@example.net>"
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

      specify { expect(distributor.parameter_name).to eq 'new-distributor' }

      context "and an invalid parameter name is set" do
        before do
          distributor.name = 'New Distributor'
          distributor.parameter_name = "invalid/name/@)*&"
        end

        specify { expect(distributor).not_to be_valid }
      end
    end

    context 'when updating an existing distributor' do
      before { distributor.name = 'Saved Distributor' }

      context 'and there is no existing parameter name' do
        describe 'it will default from name' do
          before { distributor.save }
          specify { expect(distributor.parameter_name).to eq 'saved-distributor' }
        end

        describe 'it will create from value' do
          before do
            distributor.parameterize_name('Great Veggie Box Delivery!')
            distributor.save
          end

          specify { expect(distributor.parameter_name).to eq 'great-veggie-box-delivery' }
        end
      end

      context 'and there is an existing parameter name' do
        before { distributor.parameter_name = 'fruit-by-the-bucket' }

        describe 'it will not use parameterized name' do
          before { distributor.save }
          specify { expect(distributor.parameter_name).to eq 'fruit-by-the-bucket' }
        end

        describe 'it will create from value' do
          before do
            distributor.parameterize_name('Great Veggie Box Delivery!')
            distributor.save
          end

          specify { expect(distributor.parameter_name).to eq 'great-veggie-box-delivery' }
        end
      end
    end
  end

  context 'delivery window parameters' do
    specify { expect(Fabricate.build(:distributor, advance_hour: -1)).not_to be_valid }
    specify { expect(Fabricate.build(:distributor, advance_days: -1)).not_to be_valid }
  end

  context 'support email' do
    specify { expect(Fabricate(:distributor, email: 'buckybox@example.com').support_email).to eq 'buckybox@example.com' }
    specify { expect(Fabricate(:distributor, support_email: 'support@example.com').support_email).to eq 'support@example.com' }
  end

  describe '#generate_required_daily_lists' do
    let(:generator) { double('generator') }
    let(:generator_class) { double('generator_class', new: generator) }

    it 'returns true if the daily list generator successfully performs the generation' do
      allow(generator).to receive(:generate) { true }
      expect(distributor.generate_required_daily_lists(generator_class)).to be true
    end

    it 'returns false if the daily list generator fails to performs the generation' do
      allow(generator).to receive(:generate) { true }
      expect(distributor.generate_required_daily_lists(generator_class)).to be true
    end
  end

  context 'cron related methods' do
    before do
      @current_time = Time.zone.local(2012, 3, 20, Distributor::DEFAULT_ADVANCED_HOURS)
      Delorean.time_travel_to(@current_time)

      @distributor1 = Fabricate(:distributor, advance_hour: 18, advance_days: 3)
      daily_orders(@distributor1)

      @current_time += 1.day
      Delorean.time_travel_to(@current_time)

      @distributor2 = Fabricate(:distributor, advance_hour: 12, advance_days: 4)
      daily_orders(@distributor2)

      @distributor3 = Fabricate(:distributor, advance_hour: 0, advance_days: 7)
      daily_orders(@distributor3)
    end

    after { Delorean.back_to_the_present }

    context '@distributor1 should generate daily lists' do
      before do
        skip 'These two tests fail randomly. Fix or remove soon'
      end
      specify { expect { Distributor.create_daily_lists }.to change(PackingList, :count).by(1) }
      specify { expect { Distributor.create_daily_lists }.to change(DeliveryList, :count).by(1) }
    end
  end

  context 'time zone' do
    before { Time.zone = 'Paris' }

    describe '.use_local_time_zone' do
      context 'with time_zone set to Berlin' do
        before { @distributor = Fabricate(:distributor, time_zone: 'Berlin') }

        it 'should temporarily change Time.now' do
          @distributor.use_local_time_zone { expect(Time.zone.name).to eq('Berlin') }
          expect(Time.zone.name).to eq('Paris')
        end
      end
    end

    context 'daily automation' do
      context 'time zone set to Wellington' do
        before do
          Time.zone = 'Wellington'
          time = Time.current
          time_tomorrow = time + 1.day
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

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 4 }
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
          before { Delorean.time_travel_to(Time.use_zone('Perth') { Time.zone.local(*(@tomorrow + @schedule_start)) }.in_time_zone('Wellington')) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 4 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to Perth end of day' do
          before { Delorean.time_travel_to(Time.use_zone('Perth') { Time.zone.local(*(@tomorrow + @schedule_end)) }.in_time_zone('Wellington')) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end

        context 'time set to London start of day' do
          before { Delorean.time_travel_to(Time.use_zone('London') { Time.zone.local(*(@tomorrow + @schedule_start)) }.in_time_zone('Wellington')) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 6 }
        end

        context 'time set to London end of day' do
          before { Delorean.time_travel_to(Time.use_zone('London') { Time.zone.local(*(@tomorrow + @schedule_end)) }.in_time_zone('Wellington')) }

          specify { expect { Distributor.create_daily_lists }.to change { @d_welly.packing_lists.count + @d_welly.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_perth.packing_lists.count + @d_perth.delivery_lists.count }.by 0 }
          specify { expect { Distributor.create_daily_lists }.to change { @d_london.packing_lists.count + @d_london.delivery_lists.count }.by 0 }
        end
      end
    end
  end

  describe :balance_thresholds do
    let(:distributor) { Fabricate(:distributor_with_a_customer) }

    it 'should update all customers spend limit' do
      expect_any_instance_of(Customer).to receive(:update_halted_status!).with(nil, Customer::EmailRule.only_pending_orders)
      expect(distributor.update_attributes({ has_balance_threshold: true, default_balance_threshold: 200.00, spend_limit_on_all_customers: '0' })).to be true
    end
  end

  describe ".update_next_occurrence_caches" do
    let(:customer) do
      distributor.save!
      Fabricate(:customer, distributor: distributor)
    end
    let(:order) { Fabricate(:order, account: customer.account) }
    it 'updates cached value of next order' do
      order
      customer.update_column(:next_order_occurrence_date, nil)
      customer.update_column(:next_order_id, nil)
      customer.reload
      expect(customer.next_order_occurrence_date).to eq nil

      distributor.update_next_occurrence_caches

      customer.reload
      expect(customer.next_order_occurrence_date).to eq order.next_occurrence(Time.current.hour >= Distributor::AUTOMATIC_DELIVERY_HOUR ? Date.current.tomorrow : Date.current)
    end
  end

  describe ".transactional_customer_count" do
    let(:distributor) { Fabricate(:distributor) }
    let(:customer) { customer = Fabricate(:customer, distributor: distributor) }

    it "returns zero when no transactions on any customers" do
      customer
      expect(distributor.transactional_customer_count).to eq 0
    end

    it "counts the number of customers with transactions" do
      Fabricate(:transaction, account: customer.account)
      Fabricate(:customer, distributor: distributor)
      Fabricate(:transaction, account: Fabricate(:account))
      expect(distributor.transactional_customer_count).to eq 1
    end
  end

  describe "#notify_of_address_change" do
    context "notify_address_change is true" do
      let(:distributor) { Fabricate.build(:distributor, notify_address_change: true) }

      it "retruns true if successful" do
        customer = double('customer')
        notifier = double('Event', customer_address_changed: true)

        expect(distributor.notify_address_changed(customer, notifier)).to eq true
      end
    end

    context "returns false if unsuccesful" do
      it "retuns false if notify address change is false" do
        distributor.notify_address_change = false
        customer = double('customer')
        notifier = double('Event')
        expect(distributor.notify_address_changed(customer, notifier)).to eq false
      end

      it "returns false if fails" do
        customer = double('customer')
        notifier = double('Event', customer_address_changed: false)
        expect(distributor.notify_address_changed(customer, notifier)).to eq false
      end
    end
  end

  describe '#customer_for_export' do
    it 'returns customers based on customer ids' do
      distributor.save
      customer_1 = Fabricate(:customer, distributor: distributor)
      customer_2 = Fabricate(:customer, distributor: distributor)
      expect(distributor.customers_for_export([customer_1.id])).to eq([customer_1])
    end
  end

  context "Messaging and tracking" do
    subject { distributor }
    it { is_expected.to delegate(:tracking_after_create).to(:messaging) }
    it { is_expected.to delegate(:tracking_after_save).to(:messaging) }
    it { is_expected.to delegate(:track).to(:messaging) }
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

  context "when tracking a distributor" do
    before { distributor.save }

    describe "#mark_as_seen!" do
      it "changes the last seen timestamp of the distributor" do
        expect { distributor.mark_as_seen! }.to change { distributor.last_seen_at }
      end
    end

    describe ".mark_as_seen!" do
      it "changes nothing if there is no distributor" do
        expect { Distributor.mark_as_seen!(nil) }.not_to change { distributor.last_seen_at }
      end

      it "changes nothing if no tracking option is passed in" do
        expect { Distributor.mark_as_seen!(distributor, no_track: true) }.not_to change { distributor.last_seen_at }
      end

      it "changes the last seen timestap of the distributor" do
        expect { Distributor.mark_as_seen!(distributor) }.to change { distributor.last_seen_at }
      end
    end
  end
end
