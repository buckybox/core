# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BuckyBox::Application.initialize!

BuckyBox::Application.configure do
  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( admin.js admin.css distributor.js distributor.css customer.js customer.css print.js print.css sign_up_wizard.js sign_up_wizard.css )
  config.assets.precompile += %w( leaflet.js leaflet.css )
end
