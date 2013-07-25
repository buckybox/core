require 'spec_helper'

describe Delivery do
  let(:delivery) { Fabricate(:delivery) }
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
          specify { Fabricate(:delivery, status: s).should be_valid }
          specify { Fabricate(:delivery, status: s, status_change_type: 'manual').should be_valid }
        end
      end

      specify { expect {Fabricate(:delivery, status: 'lame')}.to raise_error(ActiveRecord::RecordInvalid, /Status is invalid/) }
      specify { expect {Fabricate(:delivery, status_change_type: 'lame')}.to raise_error(ActiveRecord::RecordInvalid, /Status change type lame is not a valid status change type/)}
    end

    describe '#future_status?' do
      specify { Fabricate(:delivery, status: 'pending').future_status?.should be_true }
      specify { Fabricate(:delivery, status: 'cancelled').future_status?.should be_false }
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

    context 'batch change' do
      before do
        @delivery1 = Fabricate(:delivery)
        @delivery2 = Fabricate(:delivery, status: :delivered)

        @deliveries = [@delivery1, delivery, @delivery2]

        delivery.stub(:save) { true }
      end

      context 'all save' do
        before { @delivery1.stub(:save) { true } }
        specify { Delivery.change_statuses(@deliveries, 'deliver').should be_true }
      end

      context 'one save fails' do
        before { @delivery1.stub(:save) { false } }
        specify { Delivery.change_statuses(@deliveries, 'deliver').should be_false }
      end
    end
  end

  describe '.auto_deliver' do
    specify { expect { Fabricate(:delivery).should change(Delivery.last, :status).to('delivered') } }
    specify { expect { Fabricate(:delivery, status_change_type: 'manual', status: 'delivered').should_not change(Delivery.last, :status_change_type).to('auto') } }
    specify { expect { Fabricate(:delivery, status_change_type: 'manual', status: 'cancelled').should_not change(Delivery.last, :status).to('delivered') } }
    specify { expect { Fabricate(:delivery, status_change_type: 'manual', status: 'pending').should_not change(Delivery.last, :status).to('delivered') } }
  end

  describe '#reposition!' do
    specify { expect { delivery.reposition!(101) }.to change(delivery, :position).to(101) }
  end

  describe "#tracking" do
    context "when I change the status to 'delivered'" do
      before do
        delivery.status.should_not eq 'delivered'
        delivery.deliver
      end
    end

    %w(engaged distributor_delivered_order).each do |event|
      it "sends the '#{event}' event" do
        Bucky::Tracking.instance.should_receive(:event). \
          with(delivery.distributor.id, event).at_least(:once)

        delivery.save
      end
    end
  end
end
