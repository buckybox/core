require 'spec_helper'

describe Bucky::Tracking do
  describe "#event" do
    subject { Bucky::Tracking.instance }
    let(:tracking) { subject }

    it "raises if the identity is nil" do
      expect do
        tracking.event(nil, 'test')
      end.to raise_error TypeError
    end
  end
end
