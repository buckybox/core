require 'spec_helper'

describe Delivery do
  let(:delivery) { Fabricate.build(:delivery) }
  let(:package) { delivery.package }

  let(:delivery_pending) { Fabricate(:delivery, status: 'pending') }
  let(:delivery_cancelled) { Fabricate(:delivery, status: 'cancelled' ) }
  let(:delivery_delivered) { Fabricate(:delivery, status: 'delivered' ) }

  specify { delivery.should be_valid }
  specify { delivery.status.should == 'pending' }
  specify { delivery.status_change_type.should == 'auto' }

  context :status do
    describe 'validity' do
      describe "for new record" do
        (Delivery::STATUS - ['delivered']).each do |s|
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
    #Account balance starts at $0.00
    context 'when changed to delivered' do
      shared_examples 'it deducts accounts' do
        before { @delivery.save }

        specify { @delivery.account.balance.should == @starting_balance - @package.price }
        specify { @delivery.transactions.should_not be_empty }
        specify { @delivery.transactions.last.transactionable.should == @delivery }
        specify { @delivery.transactions.last.amount.should == -@package.price }
      end

      context 'from pending' do
        before do
          @delivery = delivery_pending
          @package = @delivery.package

          @starting_balance = @delivery.account.balance
          @delivery.status = 'delivered'
        end

        it_behaves_like 'it deducts accounts'
      end

      context 'from cancelled' do
        before do
          @delivery = delivery_cancelled
          @package = @delivery.package

          @starting_balance = @delivery.account.balance
          @delivery.status = 'delivered'
        end

        it_behaves_like 'it deducts accounts'
      end
    end

    # Account balance starts at $-20.00
    context 'when changed from delivered' do
      shared_examples 'it adds to accounts' do
        before { @delivery.save }

        specify { @delivery.account.balance.should == @starting_balance + @package.price }
        specify { @delivery.transactions.should_not be_empty }
        specify { @delivery.transactions.last.transactionable.should == @delivery }
        specify { @delivery.transactions.last.amount.should == @package.price }
      end

      context 'to pending' do
        before do
          @delivery = delivery_delivered
          @package = @delivery.package

          @starting_balance = @delivery.account.balance
          @delivery.status = 'pending'
        end

        it_behaves_like 'it adds to accounts'
      end

      context 'to cancelled' do
        before do
          @delivery = delivery_delivered
          @package = @delivery.package

          @starting_balance = @delivery.account.balance
          @delivery.status = 'cancelled'
        end

        it_behaves_like 'it adds to accounts'
      end
    end
  end

  describe '.change_statuses' do
    before { @deliveries = [delivery] }

    specify { Delivery.change_statuses(@deliveries, 'bad_status').should be_false }
    specify { Delivery.change_statuses(@deliveries, 'rescheduled').should be_false }
    specify { Delivery.change_statuses(@deliveries, 'delivered').should be_true }
    specify { Delivery.change_statuses(@deliveries, 'rescheduled', date: (Date.current + 2.days).to_s).should be_true }
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
