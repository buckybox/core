require "spec_helper"

describe Event do
  let(:event) { Fabricate(:event) }

  specify { event.should be_valid }

  describe "#dismiss!" do
    before { event.dismiss! }
    specify { event.dismissed.should be_true }
  end

  shared_examples_for "an event" do
    let!(:new_event) { Event.public_send(event_name, resource) }

    it "removes duplicate events" do
      new_event
      event2 = new_event

      expect(Event.all_for_distributor(resource.distributor)).to eq [event2]
    end

    it "includes a clickable customer badge" do
      expect(new_event.message).to include "customer-badge", "<a"
    end
  end

  describe ".new_webstore_customer" do
    let(:event_name) { "new_webstore_customer" }
    let(:resource) { Fabricate(:customer) }

    it_behaves_like "an event"
  end

  describe ".customer_halted" do
    let(:event_name) { "customer_halted" }
    let(:resource) { Fabricate(:customer) }

    it_behaves_like "an event"
  end

  describe ".customer_address_changed" do
    let(:event_name) { "customer_address_changed" }
    let(:resource) { Fabricate(:customer) }

    it_behaves_like "an event"
  end

  describe ".new_webstore_order" do
    let(:event_name) { "new_webstore_order" }
    let(:resource) { Fabricate(:order) }

    it_behaves_like "an event"
  end

  describe ".all_for_distributor" do
    let(:distributor) { Fabricate(:distributor) }

    it "returns all events for a distributor" do
      event1 = Fabricate(:event, distributor: distributor)
      event2 = Fabricate(:event, distributor: distributor)

      expect(Event.all_for_distributor(distributor)).to match_array [event1, event2]
    end

    it "returns only the distributor's events" do
      event = Fabricate(:event,  distributor: distributor)
      Fabricate(:event)

      expect(Event.all_for_distributor(distributor)).to eq [event]
    end
  end
end
