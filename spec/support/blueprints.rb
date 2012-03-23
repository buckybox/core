require 'machinist/active_record'

# Add your blueprints here.
#
# e.g.
#   Post.blueprint do
#     title { "Post #{sn}" }
#     body  { "Lorem ipsum..." }
#   end

Address.blueprint do
  customer { object.customer || Customer.make(:address => object) }
  address_1 { '1 Address St' }
  suburb { 'Suburb' }
  city { 'City' }
end

Address.blueprint(:full) do
  address_2 { 'Apartment 1' }
  postcode { '00000' }
  delivery_note { 'This is a note.' }
  phone_1 { '11-111-111-1111' }
  phone_2 { '22-222-222-2222' }
  phone_3 { '33-333-333-3333' }
end

Customer.blueprint do
  distributor
  route
  first_name { "First Name #{sn}" }
  email { "customer#{sn}@example.com" }
  password { 'password' }
  password_confirmation { 'password' }
  account
  address
  # after_create { |customer| Fabricate(:account, customer: customer) }
  # after_create { |customer| Fabricate(:address, customer: customer) }
end

Box.blueprint do
  distributor
  name { "Box #{sn}" }
  description { "A description about this box." }
  price { 10 }
end

Distributor.blueprint do
  name { "Distributor #{sn}" }
  email { "distributor#{sn}@example.com" }
  password { 'password' }
  password_confirmation { 'password' }
end

BankInformation.blueprint do
  distributor
  name { "Bank #{sn}" }
  account_name { "Account Name #{sn}" }
  account_number { sn }
  customer_message { "Message #{sn}" }
end

Event.blueprint(:billing) do
  distributor_id { 1 }
  event_category { 'billing' }
  event_type { Event::EVENT_TYPES[:invoice_reminder] }
  invoice_id { 1 }
  reconciliation_id { 1 }
end

InvoiceInformation.blueprint do
  distributor
  gst_number { sn }
  billing_address_1 { "#{sn} Invoice Information St" }
  billing_suburb { "Suburb #{sn}" }
  billing_city { "City #{sn}" }
  billing_postcode { 1000 }
  phone { 1000000000 }
end

Transaction.blueprint do
  account
  kind { 'delivery' }
  amount { 1000 }
  description { "Description #{sn}" }
end

Account.blueprint do
end

Route.blueprint do
  distributor { Distributor.make(:routes => [object]) }
  name { "Route #{sn}" }
  fee { 0 }
  monday { true }
end

DeliveryList.blueprint do
  distributor
  date { Date.current - 1.day }
end