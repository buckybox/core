require 'spec_helper'

describe Delivery do
  let(:delivery) { Fabricate.build(:delivery) }
  let(:package) { delivery.package }

  let(:delivery_pending) { Fabricate(:delivery, status: 'pending') }
  let(:delivery_cancelled) { Fabricate(:delivery, status: 'cancelled') }
  let(:delivery_delivered) { Fabricate(:delivery, status: 'delivered') }

  specify { delivery.should be_valid }
  specify { delivery.status.should == 'pending' }
  specify { delivery.status_change_type.should == 'auto' }

  context :status do
    describe 'validity' do
      describe "for new record" do
        (Delivery.state_machines[:status].states.map(&:name) - [:delivered]).each do |s|
          specify { Fabricate.build(:delivery, status: s).should be_valid }
          specify { Fabricate.build(:delivery, status: s, status_change_type: 'manual').should be_valid }
        end
      end

      specify { Fabricate.build(:delivery, status: 'lame').should_not be_valid }
      specify { Fabricate.build(:delivery, status_change_type: 'lame').should_not be_valid }
    end

    describe '#future_status?' do
      specify { Fabricate.build(:delivery, status: 'pending').future_status?.should be_true }
      specify { Fabricate.build(:delivery, status: 'cancelled').future_status?.should be_false }
    end
  end

  context 'changing status' do
    context 'when changed to delivered' do
      shared_examples 'it deducts accounts' do
        before do
          @price            = @delivery.package.price
          @starting_balance = @delivery.account.balance
          @delivery.deliver
        end

        specify { @delivery.deducted?.should be_true }
        specify { @delivery.account(true).balance.should == @starting_balance - @price }
      end

      context 'from pending' do
        before { @delivery = delivery_pending }

        it_behaves_like 'it deducts accounts'
      end

      context 'from cancelled' do
        before { @delivery = delivery_cancelled }

        it_behaves_like 'it deducts accounts'
      end
    end

    context 'when changed from delivered' do
      before do
          @delivery = delivery_pending
          @starting_balance = @delivery.account.balance
          @delivery.deliver
      end

      shared_examples 'it adds to accounts' do
        specify { @delivery.deducted?.should be_false }
        specify { @delivery.account(true).balance.should == @starting_balance }
      end

      context 'to pending' do
        before { @delivery.pend }

        it_behaves_like 'it adds to accounts'
      end

      context 'to cancelled' do
        before { @delivery.cancel }

        it_behaves_like 'it adds to accounts'
      end
    end
  end

  describe '.change_statuses' do
    before do
      delivery.save
      @deliveries = [delivery]
    end

    specify { Delivery.change_statuses(@deliveries, 'bad_status').should be_false }
    specify { Delivery.change_statuses(@deliveries, 'cancel').should be_true }
    specify { Delivery.change_statuses(@deliveries, 'deliver').should be_true }
  end

  describe '.auto_deliver' do
    specify { expect { Fabricate.build(:delivery).should change(Delivery.last, :status).to('delivered') } }
    specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'delivered').should_not change(Delivery.last, :status_change_type).to('auto') } }
    specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'cancelled').should_not change(Delivery.last, :status).to('delivered') } }
    specify { expect { Fabricate.build(:delivery, status_change_type: 'manual', status: 'pending').should_not change(Delivery.last, :status).to('delivered') } }
  end

  describe '.csv_headers' do
    specify { Delivery.csv_headers.size.should == 19 }
  end

  describe '#to_csv' do
    specify { delivery.to_csv[0].should == delivery.route.name }
    specify { delivery.to_csv[3].should == delivery.order.id }
    specify { delivery.to_csv[4].should == delivery.id }
    specify { delivery.to_csv[5].should == delivery.date.strftime("%-d %b %Y") }
    specify { delivery.to_csv[6].should == delivery.customer.number }
    specify { delivery.to_csv[7].should == delivery.customer.first_name }
  end

  describe '#reposition!' do
    specify { expect { delivery.reposition!(101) }.to change(delivery, :position).to(101) }
  end
end
