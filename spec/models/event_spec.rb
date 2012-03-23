require 'spec_helper'

describe Event do
  specify { Fabricate.build(:customer_event).should be_valid }
  specify { Fabricate.build(:billing_event).should be_valid }
  specify { Fabricate.build(:delivery_event).should be_valid }

  specify { Fabricate.build(:billing_event, event_category: 'not_a_category').should_not be_valid }
  specify { Fabricate.build(:billing_event, event_type: 'not_a_type').should_not be_valid }

  context '#dismiss!' do
    before do
      @event = Fabricate(:billing_event)
      @event.dismiss!
    end

    specify { @event.dismissed.should be_true }
  end

  context 'customer event methods' do
    before { @customer = Fabricate(:customer) }

    context '.new_customer' do
      specify { expect { Event.new_customer(@customer) }.should change(Event, :count).by(1) }
      specify { Event.new_customer(@customer).event_type.should == Event::EVENT_TYPES[:customer_new] }
    end

    context '.create_call_reminder' do
      specify { expect { Event.create_call_reminder(@customer) }.should change(Event, :count).by(1) }
      specify { Event.create_call_reminder(@customer).event_type.should == Event::EVENT_TYPES[:customer_call_reminder] }
    end
  end
end
