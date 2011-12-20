require 'spec_helper'

describe Event do
  before :all do 
    @event = Fabricate(:billing_event)
  end

  specify { @event.should be_valid }
end
