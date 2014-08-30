object @webstore => :webstore
attributes :name, :currency, :time_zone, :city, :sidebar_description, :facebook_url, :phone, :email, :company_logo, :line_items
attributes :payment_options

attributes :require_phone, :require_address_1, :require_address_2, :require_suburb, :require_city, :require_postcode, :require_delivery_note
attributes :collect_phone, :collect_delivery_note

attribute :active_webstore => :active

node(:id) { |webstore| webstore.parameter_name }

node(:company_team_image) { |webstore| webstore.company_team_image.photo.url }


