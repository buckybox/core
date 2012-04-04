require 'spec_helper'

describe PackingList do
  specify { Fabricate.build(:packing_list).should be_valid }

  describe '#mark_all_as_auto_packed' do
    before do
      @packing_list = Fabricate(:packing_list)
      3.times { Fabricate(:package, packing_list: @packing_list) }
    end

    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[0], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should_not change(@packing_list.packages[0], :packing_method) }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[1], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should_not change(@packing_list.packages[1], :packing_method) }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[2], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should_not change(@packing_list.packages[2], :packing_method) }
  end

  describe '.collect_lists' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, distributor: @distributor)
      3.times { Fabricate(:recurring_order, completed: true, box: box) }

      time_travel_to Date.parse('2012-01-30')

      ((Date.current - 1.week)..Date.current).each { |date| PackingList.generate_list(@distributor, date) }
    end

    specify { PackingList.collect_lists(@distributor, (Date.current - 1.week), (Date.current + 1.week)).should be_kind_of(Array) }

    after { back_to_the_present }
  end

  describe '.generate_list' do
    before do
      time_travel_to Date.current

      @distributor = Fabricate(:distributor)
      daily_orders(@distributor)

      @advance_days = Distributor::DEFAULT_ADVANCED_DAYS
      @generate_date = Date.current + @advance_days.days

      time_travel_to @generate_date
    end

    specify { expect { PackingList.generate_list(@distributor, @generate_date) }.should change(@distributor.packing_lists, :count).from(@advance_days).to(@advance_days + 1) }
    specify { expect { PackingList.generate_list(@distributor, @generate_date) }.should change(@distributor.packages, :count).from(0).to(3) }

    after { back_to_the_present }
  end
end
