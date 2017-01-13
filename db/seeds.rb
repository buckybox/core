require "fabrication"

email = "demo@example.net"
password = "changeme"

Fabricate.create(:distributor_with_everything,
  name: "Demo Veggie Group",
  email: email,
  password: password,
)
