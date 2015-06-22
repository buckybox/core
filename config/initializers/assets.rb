# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( admin.js admin.css distributor.js distributor.css customer.js customer.css print.js print.css sign_up_wizard.js sign_up_wizard.css )
Rails.application.config.assets.precompile += %w( leaflet.js leaflet.css )
