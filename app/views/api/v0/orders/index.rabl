# app/views/api/v0/orders/index.rabl
collection @orders
attributes :id, :box_id, :created_at, :updated_at, :active
attribute :account_id => :customer_id
