# TODO: Someday ehter split up this Defaults class into other clases or modules, add better
# dependancy injecton or both. Until then, I'm doing this.
class Distributor; end
class LineItem; end
class EmailTemplate; end
class Rails; end unless defined? Rails
class Figaro; end unless defined? Figaro

require_relative "../../../app/models/distributor/defaults"

describe Distributor::Defaults do

  let(:distributor) do
    double("distributor",
           parameter_name: "veg-people",
           name: "Veg People",
           save: true,
           bank_information: double.as_null_object,
           omni_importers: double.as_null_object,
           "email_templates=" => true,
          )
  end

  # Gross I know but what has to be done right now with this class to have fast test and not to touch the DB
  before do
    LineItem.stub(:add_defaults_to)
    EmailTemplate.stub(:new)

    url_helper = double("url_helper" , new_customer_session_url: true, new_customer_password_url: true)
    Rails.stub_chain(:application, :routes, :url_helpers) { url_helper }

    Figaro.stub_chain(:env, :host)
  end

  shared_examples_for "a distributor with populated defaults" do
    it "creates the default line items for a distributor" do
      LineItem.should_receive(:add_defaults_to).with(distributor)
    end

    it "creates the default email templates for a distributor" do
      EmailTemplate.should_receive(:new)
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

