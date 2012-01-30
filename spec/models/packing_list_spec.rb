require 'spec_helper'

describe PackingList do
  before { @packing_list = Fabricate(:packing_list) }

  specify { @packing_list.should be_valid }

  describe '#mark_all_as_auto_packed' do
    before { 3.times { Fabricate(:package, :packing_list => @packing_list) } }

    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[0], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[0], :packing_method).from(nil).to('auto') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[1], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[1], :packing_method).from(nil).to('auto') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[2], :status).from('unpacked').to('packed') }
    specify { expect { @packing_list.mark_all_as_auto_packed }.should change(@packing_list.packages[2], :packing_method).from(nil).to('auto') }
  end

  describe '#collect_lists' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, :distributor => @distributor)
      3.times { Fabricate(:recurring_order, :completed => true, :box => box) }

      time_travel_to Date.parse('2012-01-30')

      ((Date.current - 1.week)..Date.current).each { |date| PackingList.generate_list(@distributor, date) }
    end

    specify { PackingList.collect_lists(@distributor, (Date.current - 1.week), (Date.current + 1.week)).should be_kind_of(Array) }

    after { back_to_the_present }
  end

  describe '#generate_list' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, :distributor => @distributor)
      3.times { Fabricate(:recurring_order, :box => box, :completed => true) }
    end

    specify { expect { PackingList.generate_list(@distributor, (Date.current + 1.day)) }.should change(@distributor.packing_lists, :count).from(0).to(1) }
    specify { expect { PackingList.generate_list(@distributor, (Date.current + 1.day)) }.should change(@distributor.packages, :count).from(0).to(3) }

    after { back_to_the_present }
  end
end
