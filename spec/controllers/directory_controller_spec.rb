require "spec_helper"

RSpec.describe DirectoryController, type: :controller do
  describe "#index" do
    render_views

    it "renders the expected HTML" do
      distributor = Fabricate(:existing_distributor_with_everything, name: "Local Veg")
      allow(Distributor).to receive(:active).and_return([distributor])
      Fabricate(:localised_address, addressable: distributor, street: "89 Courtenay Place", city: "Wellington")

      result = <<-RESULT
<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=utf-8 />\n  <title>Bucky Box - Web Store Directory</title>\n  <!-- <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' /> -->\n  <link href=\"/assets/leaflet.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />\n  <script src=\"/assets/leaflet.js\" type=\"text/javascript\"></script>\n  <style>\n    html, body { margin: 0; padding: 0; height: 100%; }\n    #map { min-height: 100%; }\n  </style>\n</head>\n<body>\n  <div id=\"map\"></div>\n\n  <script>\n    var map = L.map('map').setView([20, 40], 2);\n    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);\n\n    var locations = [["-41.2930368", "174.7794396"]];\n    var addresses = ["89 Courtenay Place Wellington NZ"];\n    var names = [\"Local Veg\"];\n    var webstores = [\"https://store.buckybox.com/local-veg\"];\n\n    locations.forEach(function(loc, i) {\n      marker = L.marker(loc).addTo(map);\n      marker.bindPopup(\"<b><a href='\" + webstores[i] + \"' target='_blank'>\" + names[i] + \"</a></b><br>\" + addresses[i]);\n    });\n  </script>\n</body>\n</html>\n
      RESULT

      get :index
      expect(response.body).to eq(result)
    end
  end
end
