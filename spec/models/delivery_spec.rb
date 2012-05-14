require 'spec_helper'

describe Delivery do
  let(:delivery) { Fabricate.build(:delivery) }

  specify { delivery.should be_valid }
  specify { delivery.status.should == 'pending' }
  specify { delivery.status_change_type.should == 'auto' }

  context :status do
    describe 'validity' do
      describe "for new record" do
        (Delivery::STATUS - ['delivered']).each do |s|
          it "is valid for status = #{s}" do
            Fabricate.build(:delivery, status: s).should be_valid
          end

          it "is valid if manually changed to status = #{s}" do
            Fabricate.build(:delivery, status: s, status_change_type: 'manual').should be_valid
          end
        end
      end

      describe "for existing record" do
        before do
          delivery.save!
          delivery.order.save!
          delivery.order.account.save!
        end

        it "is valid for status = delivered" do
          delivery.status = 'delivered'
          delivery.should be_valid
        end

        it "is valid if manually changed to status = delivered" do
          delivery.save!
          delivery.status = 'delivered'
          delivery.status_change_type = 'manual'
          delivery.should be_valid
        end
      end

      specify { Fabricate.build(:delivery, status: 'lame').should_not be_valid }
      specify { Fabricate.build(:delivery, status_change_type: 'lame').should_not be_valid }
    end

    describe '#future_status?' do
      it "is true if status is pending" do
        Fabricate.build(:delivery, status: 'pending').future_status?.should be_true
      end

      it "is false if status is not pending" do
        Fabricate.build(:delivery, status: 'cancelled').future_status?.should be_false
      end
    end
  end

  context :changing_status do
    (Delivery::STATUS - %w(rescheduled repacked)).each do |os|
      context '#status_changed' do
        before(:each) do
          @delivery = Fabricate(:delivery, status: os)

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
              specify { expect { @delivery.save }.should change(Event, :count).by(1) }
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
        @deliveries = [Fabricate.build(:delivery)]
      end

      specify { Delivery.change_statuses(@deliveries, 'bad_status').should be_false }
      specify { Delivery.change_statuses(@deliveries, 'rescheduled').should be_false }
      specify { Delivery.change_statuses(@deliveries, 'delivered').should be_true }
      specify { Delivery.change_statuses(@deliveries, 'rescheduled', date: (Date.current + 2.days).to_s).should be_true }
    end

    context '#self.auto_deliver' do
      specify { expect { Fabricate.build(:delivery).should change(Delivery.last, :status).to('delivered') } }
      specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'delivered').should_not change(Delivery.last, :status_change_type).to('auto') } }
      specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'cancelled').should_not change(Delivery.last, :status).to('delivered') } }
      specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'pending').should_not change(Delivery.last, :status).to('delivered') } }
    end
  end

  context '.csv_headers' do
    specify { Delivery.csv_headers.size.should == 19 }
  end

  context '#to_csv' do
    specify { delivery.to_csv[0].should == delivery.route.name }
    specify { delivery.to_csv[3].should == delivery.order.id }
    specify { delivery.to_csv[4].should == delivery.id }
    specify { delivery.to_csv[5].should == delivery.date.strftime("%-d %b %Y") }
    specify { delivery.to_csv[6].should == delivery.customer.number }
    specify { delivery.to_csv[7].should == delivery.customer.first_name }
  end
end
