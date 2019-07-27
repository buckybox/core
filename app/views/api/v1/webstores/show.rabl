object @webstore => :webstore

cache [@webstore, @webstore.line_items.hash]

attributes :name, :locale, :currency, :time_zone, :city, :sidebar_description, :facebook_url, :phone, :email
attributes :line_items, :payment_options, :email_customer_on_new_webstore_order
attributes :paypal_email, :ga_tracking_id

attributes :require_phone, :require_address_1, :require_address_2, :require_suburb, :require_city, :require_postcode, :require_delivery_note
attributes :collect_phone, :collect_delivery_note

attribute :active_webstore => :active

node(:id) { |webstore| webstore.parameter_name }

node(:company_logo) do |webstore|
  webstore.company_logo.banner.url.present? ? ["//", Figaro.env.host_with_port, image_path(webstore.company_logo.banner.url)].join : nil
end

node(:company_team_image) do |webstore|
  webstore.company_team_image.photo.url.present? ? ["//", Figaro.env.host_with_port, image_path(webstore.company_team_image.photo.url)].join : nil
end

node(:cod_payment_message) { |webstore| webstore.bank_information.cod_payment_message }

child(:bank_information) do |bank_information|
  if @webstore.payment_bank_deposit
    {
      bank_name: :bank_name,
      account_name: :bank_account_name,
      account_number: :bank_account_number,
      customer_message: :customer_message
    }.each do |attr, method|
      node(attr) { |bank_information| bank_information.decorate.public_send(method).to_s }
    end
  end
end
