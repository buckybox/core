require 'spec_helper'

describe Bucky::Usercycle do
  describe "#event" do
    subject { Bucky::Usercycle.instance }
    let(:usercycle) { subject }

    it "raises if the identity is nil" do
      expect {
        usercycle.event(nil, 'test')
      }.to raise_error TypeError
    end
  end
end
