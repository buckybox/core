# app/views/api/v0/orders/index.rabl
collection @orders
attributes :id, :box_id, :active

attribute :account_id => :customer_id
