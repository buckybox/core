require "fabrication"

email = "demo@example.net"
password = "changeme"

distributor = Fabricate.create(:distributor_with_everything,
  name: "Demo Veggie Group",
  email: email,
  password: password,
)

delivery_service = Fabricate.create(:delivery_service,
  distributor: distributor,
  name: "Example delivery service",
)

_customers = Fabricate.times(3, :customer_with_address,
  distributor: distributor,
  delivery_service: delivery_service,
  first_name: "John #{rand(3)}",
)
