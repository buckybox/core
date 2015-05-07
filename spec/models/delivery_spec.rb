require 'spec_helper'

describe Delivery, :slow do
  let(:delivery) { Fabricate(:delivery) }
  let(:package) { delivery.package }

  let(:delivery_pending) { Fabricate(:delivery, status: 'pending') }
  let(:delivery_cancelled) { Fabricate(:delivery, status: 'cancelled') }
  let(:delivery_delivered) { Fabricate(:delivery, status: 'delivered') }

  specify { expect(delivery).to be_valid }
  specify { expect(delivery.status).to eq 'pending' }
  specify { expect(delivery.status_change_type).to eq 'auto' }

  context :status do
    describe 'validity' do
      describe "for new record" do
        (Delivery.state_machines[:status].states.map(&:name) - [:delivered]).each do |s|
          specify { expect(Fabricate(:delivery, status: s)).to be_valid }
          specify { expect(Fabricate(:delivery, status: s, status_change_type: 'manual')).to be_valid }
        end
      end

      specify { expect { Fabricate(:delivery, status: 'lame') }.to raise_error(ActiveRecord::RecordInvalid, /Status is invalid/) }
      specify { expect { Fabricate(:delivery, status_change_type: 'lame') }.to raise_error(ActiveRecord::RecordInvalid, /Status change type lame is not a valid status change type/) }
    end

    describe '#future_status?' do
      specify { expect(Fabricate(:delivery, status: 'pending').future_status?).to be true }
      specify { expect(Fabricate(:delivery, status: 'cancelled').future_status?).to be false }
    end
  end

  context 'changing status' do
    context 'when changed from pending' do
      before do
        @delivery = delivery_pending
        @starting_balance = @delivery.account.balance
      end

      context "to cancelled" do
        before { @delivery.cancel }

        specify { expect(@delivery.deducted?).to be false }
        specify { expect(@delivery.account(true).balance).to eq @starting_balance }
      end
    end

    context 'when changed to delivered' do
      shared_examples 'it deducts accounts' do
        before do
          @price            = @delivery.package.price
          @starting_balance = @delivery.account.balance
          @delivery.deliver
        end

        specify { expect(@delivery.deducted?).to be true }
        specify { expect(@delivery.account(true).balance).to eq @starting_balance - @price }
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
        specify { expect(@delivery.deducted?).to be false }
        specify { expect(@delivery.account(true).balance).to eq @starting_balance }
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

    specify { expect(Delivery.change_statuses(@deliveries, 'bad_status')).to be false }
    specify { expect(Delivery.change_statuses(@deliveries, 'cancel')).to be true }
    specify { expect(Delivery.change_statuses(@deliveries, 'deliver')).to be true }

    context 'batch change' do
      before do
        @delivery1 = Fabricate(:delivery)
        @delivery2 = Fabricate(:delivery, status: :delivered)

        @deliveries = [@delivery1, delivery, @delivery2]

        allow(delivery).to receive(:save) { true }
      end

      context 'all save' do
        before { allow(@delivery1).to receive(:save) { true } }
        specify { expect(Delivery.change_statuses(@deliveries, 'deliver')).to be true }
      end

      context 'one save fails' do
        before { allow(@delivery1).to receive(:save) { false } }
        specify { expect(Delivery.change_statuses(@deliveries, 'deliver')).to be false }
      end
    end
  end

  describe '.auto_deliver' do
    specify { expect { expect(Fabricate(:delivery)).to change(Delivery.last, :status).to('delivered') } }
    specify { expect { expect(Fabricate(:delivery, status_change_type: 'manual', status: 'delivered')).not_to change(Delivery.last, :status_change_type).to('auto') } }
    specify { expect { expect(Fabricate(:delivery, status_change_type: 'manual', status: 'cancelled')).not_to change(Delivery.last, :status).to('delivered') } }
    specify { expect { expect(Fabricate(:delivery, status_change_type: 'manual', status: 'pending')).not_to change(Delivery.last, :status).to('delivered') } }
  end

  describe '#reposition!' do
    specify { expect { delivery.reposition!(101) }.to change(delivery, :position).to(101) }
  end
end
