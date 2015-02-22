require "spec_helper"

RSpec.describe DirectoryController, type: :controller do

  describe "#index" do
    render_views

    # Brittle test but for now just to make sure I didn't break anything
    it "works" do
      distributor = Fabricate(:existing_distributor_with_everything)
      allow(Distributor).to receive(:active).and_return([ distributor ])
      Fabricate(:localised_address, addressable: distributor)

      result = <<-RESULT
<!DOCTYPE html>\n<html>\n<head>\n  <meta charset=utf-8 />\n  <title>Bucky Box - Web Store Directory</title>\n  <!-- <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' /> -->\n  <link href=\"/assets/leaflet.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />\n  <script src=\"/assets/leaflet.js\" type=\"text/javascript\"></script>\n  <style>\n    html, body { margin: 0; padding: 0; height: 100%; }\n    #map { min-height: 100%; }\n  </style>\n</head>\n<body>\n  <div id=\"map\"></div>\n\n  <script>\n    var map = L.map('map').setView([20, 40], 2);\n    L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(map);\n\n    var locations = [[\"-45.87189799999999\", \"170.4921815\"]];\n    var addresses = [\"0 St City 0 NZ\"];\n    var names = [\"Distributor 0\"];\n    var webstores = [\"https://my.buckybox.com/webstore/distributor-0\"];\n\n    locations.forEach(function(loc, i) {\n      marker = L.marker(loc).addTo(map);\n      marker.bindPopup(\"<b><a href='\" + webstores[i] + \"' target='_blank'>\" + names[i] + \"</a></b><br>\" + addresses[i]);\n    });\n  </script>\n</body>\n</html>\n
      RESULT

      get :index
      expect(response.body).to eq(result)
    end

  end

end
