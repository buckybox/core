require "spec_helper"

RSpec.describe DirectoryController, type: :controller do
  describe "#index" do
    render_views

    it "renders the expected HTML", :internet do
      distributor = Fabricate(:existing_distributor_with_everything, name: "Local Veg")
      allow(Distributor).to receive(:active).and_return([distributor])
      Fabricate(:localised_address, addressable: distributor, street: "89 Courtenay Place", city: "Wellington")

      result = <<-RESULT.strip
        var locations = [["-41.2930368", "174.7794396"]];\n    var addresses = ["89 Courtenay Place Wellington NZ"];\n    var names = [\"Local Veg\"];\n    var webstores = [\"https://store.buckybox.com/local-veg\"];
      RESULT

      get :index
      expect(response.body).to include result
    end
  end
end
