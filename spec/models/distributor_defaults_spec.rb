require "spec_helper"

describe DistributorDefaults do

  describe ".populate_defaults" do
    before do
      @distributor = Fabricate(:distributor,
        contact_name: "Bob"
      )

      DistributorDefaults.populate_defaults(@distributor)
    end

    specify { expect(@distributor.line_items).to_not be_empty }
    specify { expect(@distributor.email_templates).to_not be_empty }
  end

end

