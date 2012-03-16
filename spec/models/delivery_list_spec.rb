require 'spec_helper'

describe DeliveryList do
  before { @delivery_list = Fabricate(:delivery_list) }

  specify { @delivery_list.should be_valid }

  describe '#mark_all_as_auto_delivered' do
    before do
      2.times { Fabricate(:delivery, delivery_list: @delivery_list) }

      Fabricate(:delivery, status: 'pending', status_change_type: 'manual', delivery_list: @delivery_list)
      Fabricate(:delivery, status: 'cancelled', status_change_type: 'manual', delivery_list: @delivery_list)
      Fabricate(:delivery, status: 'delivered', status_change_type: 'manual', delivery_list: @delivery_list)
    end

    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should change(@delivery_list.deliveries[4], :status).from('pending').to('delivered') }
    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[4], :status_change_type) }

    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should change(@delivery_list.deliveries[3], :status).from('pending').to('delivered') }
    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[3], :status_change_type) }

    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[2], :status) }
    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[2], :status_change_type) }

    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[1], :status) }
    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[1], :status_change_type) }

    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[0], :status) }
    specify { expect { @delivery_list.mark_all_as_auto_delivered }.should_not change(@delivery_list.deliveries[0], :status_change_type) }
  end

  describe '#collect_lists' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, distributor: @distributor)
      3.times { Fabricate(:recurring_order, completed: true, box: box) }

      time_travel_to Date.parse('2012-01-30')

      ((Date.current - 1.week)..Date.current).each { |date| DeliveryList.generate_list(@distributor, date) }
    end

    specify { DeliveryList.collect_lists(@distributor, (Date.current - 1.week), (Date.current + 1.week)).should be_kind_of(Array) }

    after { back_to_the_present }
  end

  describe '#generate_list' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, distributor: @distributor)
      3.times { Fabricate(:recurring_order, box: box, completed: true) }
      PackingList.generate_list(@distributor, (Date.current + 1.day))
    end

    specify { expect { DeliveryList.generate_list(@distributor, (Date.current + 1.day)) }.should change(@distributor.delivery_lists, :count).from(0).to(1) }
    specify { expect { DeliveryList.generate_list(@distributor, (Date.current + 1.day)) }.should change(@distributor.deliveries, :count).from(0).to(3) }

    after { back_to_the_present }
  end

  describe '#all_finished?' do
    context 'no deliveries are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: @delivery_list)
        Fabricate(:delivery, status: 'delivered', delivery_list: @delivery_list)
      end

      specify { @delivery_list.all_finished?.should be_true }
    end

    context 'has deliveries that are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: @delivery_list)
        Fabricate(:delivery, status: 'pending', delivery_list: @delivery_list)
      end

      specify { @delivery_list.all_finished?.should_not be_true }
    end
  end
end
