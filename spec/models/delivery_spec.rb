require 'spec_helper'

describe Delivery do
  specify { Fabricate(:delivery).should be_valid }

  context :status do
    describe 'validity' do
      Delivery::STATUS.each do |s|
        specify { Fabricate.build(:delivery, :status => s).should be_valid }
      end

      specify { Fabricate.build(:delivery, :status => 'lame').should_not be_valid }
    end

    describe '#future_status?' do
      specify { Fabricate.build(:delivery, :status => 'pending').future_status?.should be_true }

      (Delivery::STATUS - %w(pending)).each do |s|
        specify { Fabricate.build(:delivery, :status => s).future_status?.should be_false }
      end
    end
  end

  context :changing_status do
    (Delivery::STATUS - %w(rescheduled repacked)).each do |os|
      context '#status_changed' do
        before(:each) do
          @delivery = Fabricate(:delivery, :status => os)

          @account = @delivery.account
          @cost = @delivery.order.price * @delivery.order.quantity
        end

        (Delivery::STATUS - %w(rescheduled repacked)).each do |ns|
          next if os == ns

          describe "from #{os} to #{ns}" do
            before(:each) do
              @delivery.status = ns

              @schedule_hash = Order.find(@delivery.order.id).schedule.to_hash
            end

            if ns == 'delivered'
              specify { expect { @delivery.save }.should change(@account, :balance).by(@cost * -1) }
            elsif os == 'delivered'
              specify { expect { @delivery.save }.should change(@account, :balance).by(@cost) }
            else
              specify { expect { @delivery.save }.should_not change(@account, :balance) }
            end

            it 'should not affect the order schedule' do
              @delivery.save
              Order.find(@delivery.order.id).schedule.to_hash.to_s.should == @schedule_hash.to_s
            end
            specify { expect { @delivery.save }.should_not change(@delivery.order.deliveries, :count) }
          end
        end
      end
    end

    context '#self.change_statuses' do
      before do
        @deliveries = []
        3.times { |s| @deliveries << Fabricate(:delivery) }
      end

      specify { Delivery.change_statuses(@deliveries, 'bad_status').should be_false }
      specify { Delivery.change_statuses(@deliveries, 'rescheduled').should be_false }
      specify { Delivery.change_statuses(@deliveries, 'delivered').should be_true }
      specify { Delivery.change_statuses(@deliveries, 'rescheduled', :date => (Date.today + 2.days).to_s).should be_true }
    end
  end
end
