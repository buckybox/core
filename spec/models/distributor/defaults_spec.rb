require "spec_helper"

describe Distributor::Defaults do
  let(:distributor) { Fabricate(:distributor) }

  shared_examples_for "a distributor with populated defaults" do
    it "creates the default line items for a distributor" do
      expect(LineItem).to receive(:add_defaults_to).with(distributor)
    end

    it "creates the default email templates for a distributor" do
      expect(EmailTemplate).to receive(:new).at_least(1).times
    end
  end

  describe ".populate_defaults" do
    after { Distributor::Defaults.populate_defaults(distributor) }

    it_behaves_like "a distributor with populated defaults"
  end

  describe "#populate_defaults" do
    after do
      distributor_defaults = Distributor::Defaults.new(distributor)
      distributor_defaults.populate_defaults
    end

    it_behaves_like "a distributor with populated defaults"
  end
end
