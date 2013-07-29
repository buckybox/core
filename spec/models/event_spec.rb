require 'spec_helper'

describe Event do
  let(:customer_event) { Fabricate(:customer_event) }
  let(:billing_event)  { Fabricate(:billing_event)  }
  let(:delivery_event) { Fabricate(:delivery_event) }

  specify { customer_event.should be_valid }
  specify { billing_event.should be_valid }
  specify { delivery_event.should be_valid }

  specify { expect{ Fabricate(:billing_event, event_category: 'not_a_category')}.to raise_error(ActiveRecord::RecordInvalid, /Event category is not included in the list/)}
  specify { expect{ Fabricate(:billing_event, event_type: 'not_a_type')}.to raise_error(ActiveRecord::RecordInvalid, /Event type is not included in the list/)}

  context '#dismiss!' do
    before { customer_event.dismiss! }
    specify { customer_event.dismissed.should be_true }
  end

  context 'customer event methods' do
    before do
      @customer = Fabricate(:customer)
      @customer.stub(:id).and_return(1)
    end

    context '.new_customer' do
      specify { expect { Event.new_customer(@customer) }.to change(Event, :count).by(1) }
      specify { Event.new_customer(@customer).event_type.should == Event::EVENT_TYPES[:customer_new] }
    end

    context '.create_call_reminder' do
      specify { expect { Event.create_call_reminder(@customer) }.to change(Event, :count).by(1) }
      specify { Event.create_call_reminder(@customer).event_type.should == Event::EVENT_TYPES[:customer_call_reminder] }
    end

    context '.customer_changed_address' do
      specify { expect { Event.customer_changed_address(@customer) }.to change(Event, :count).by(1) }
      specify { Event.customer_changed_address(@customer).event_type.should == Event::EVENT_TYPES[:customer_address_changed] }
    end
  end
end
