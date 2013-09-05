require "spec_helper"

describe DistributorDefaults do

  describe ".populate_defaults" do
    before do
      @distributor = Fabricate(:distributor,
        contact_name: "Bob"
      )
      @distributor.stub(:omni_importers) do
        double(bank_deposit: [ double(bank_name: "KiwiBank") ])
      end

      DistributorDefaults.populate_defaults(@distributor)
    end

    specify { expect(@distributor.line_items).to_not be_empty }
    specify { expect(@distributor.bank_information.name).to eq("KiwiBank") }
    specify { expect(@distributor.bank_information.account_name).to eq("Bob") }
  end

end
