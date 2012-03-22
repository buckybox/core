require 'spec_helper'

describe Event do
  let(:event) { Event.make(:billing) }

  context :validation do
    specify { Event.make(:billing).should be_valid }
    specify { Event.make(:billing, :event_category => "not_a_category").should_not be_valid }
    specify { Event.make(:billing, :event_type => "not_a_type" ).should_not be_valid }
  end

  context "#dismiss!" do
    before { event.dismiss! }

    specify { event.dismissed.should be_true }
  end
end
