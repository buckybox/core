object @webstore => :webstore
attributes :name, :currency, :time_zone, :city, :sidebar_description, :facebook_url, :phone, :email, :company_logo, :line_items, :paypal_email
attributes :payment_options, :email_customer_on_new_webstore_order

attributes :require_phone, :require_address_1, :require_address_2, :require_suburb, :require_city, :require_postcode, :require_delivery_note
attributes :collect_phone, :collect_delivery_note

attribute :active_webstore => :active

node(:id) { |webstore| webstore.parameter_name }

node(:company_team_image) { |webstore| webstore.company_team_image.photo.url }

child(:bank_information) do |bank_information|
  {
    bank_name: :name,
    account_name: :account_name,
    account_number: :account_number,
    customer_message: :customer_message
  }.each do |attr, method|
    node(attr) { |bank_information| bank_information.decorate.public_send(method) }
  end
end

node(:cod_payment_message) { |webstore| webstore.bank_information.cod_payment_message }
