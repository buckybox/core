require 'spec_helper'

describe Event do
  let(:customer_event) { Fabricate.build(:customer_event) }
  let(:billing_event)  { Fabricate.build(:billing_event)  }
  let(:delivery_event) { Fabricate.build(:delivery_event) }

  specify { customer_event.should be_valid }
  specify { billing_event.should be_valid }
  specify { delivery_event.should be_valid }

  specify { Fabricate.build(:billing_event, event_category: 'not_a_category').should_not be_valid }
  specify { Fabricate.build(:billing_event, event_type: 'not_a_type').should_not be_valid }

  context '#dismiss!' do
    before { customer_event.dismiss! }
    specify { customer_event.dismissed.should be_true }
  end

  context 'customer event methods' do
    before do
      @customer = Fabricate.build(:customer)
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
  end
end
