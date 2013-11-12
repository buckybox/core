# app/views/api/v0/customers/index.rabl
collection @customers
attributes :id, :address, :email

node(:read) { |post| post.read_by?(@user) }