require 'spec_helper'

describe Event do
  before do
    @event = Fabricate(:billing_event)
  end

  context :validation do
    before do
      @invalid_event1 = Fabricate.build(:billing_event, :event_category => "not_a_category")
      @invalid_event2 = Fabricate.build(:billing_event, :event_type => "not_a_type" )
    end

    specify { @event.should be_valid }
    specify { @invalid_event1.should_not be_valid }
    specify { @invalid_event2.should_not be_valid }
  end

  context "#dismiss!" do
    before {@event.dismiss!}

    specify {@event.dismissed.should be_true}
  end
end
