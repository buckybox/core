require "spec_helper"

describe Distributor::Defaults do

  let(:distributor) { Fabricate(:distributor, contact_name: "Bob") }

  shared_examples_for "a distributor with populated defaults" do
    it "creates the default line items for a distributor" do
      expect(distributor.line_items).to_not be_empty
    end

    it "creates the default email templates for a distributor" do
      expect(distributor.email_templates).to_not be_empty
    end
  end

  describe ".populate_defaults" do
    before { Distributor::Defaults.populate_defaults(distributor) }

    it_behaves_like "a distributor with populated defaults"
  end

  describe "#populate_defaults" do
    before do
      distributor_defaults = Distributor::Defaults.new(distributor)
      distributor_defaults.populate_defaults
    end

    it_behaves_like "a distributor with populated defaults"
  end

end

