require "spec_helper"

describe Distributor::Defaults do

  describe ".populate_defaults" do
    before do
      @distributor = Fabricate(:distributor,
        name: "Super Veggie"
      )
      @distributor.stub(:omni_importers) do
        double(
          bank_deposit: [ double(bank_name: "KiwiBank") ],
          paypal: []
        )
      end

      Distributor::Defaults.populate_defaults(@distributor)
    end

    specify { expect(@distributor.line_items).to_not be_empty }

    specify { expect(@distributor.bank_information.name).to eq("KiwiBank") }
    specify { expect(@distributor.bank_information.account_name).to eq("Super Veggie") }

    specify { expect(@distributor.email_templates).to_not be_empty }
  end

end

