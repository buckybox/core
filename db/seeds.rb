require "fabrication"
require "faker"

RANDOM_BALANCE = Random.new

TAG_GROUPS = [
  ["cbd", "rural", ""],
  ["new", "beta", ""],
  ["coupon", "subscription", ""]
]

def random_tag_list
  TAG_GROUPS.map{ |tag_group| tag_group.sample }.join(", ")
end

distributor = Fabricate(:distributor_with_everything, name: "Local Veggie Group", email: "fake@distributor.com")

delivery_services = [
  Fabricate(:delivery_service, distributor: distributor, name: Faker::Company.name),
  Fabricate(:delivery_service, distributor: distributor, name: Faker::Company.name),
  Fabricate(:delivery_service, distributor: distributor, name: Faker::Company.name)
]

100.times do
  customer = Fabricate(:customer_with_address,
                       distributor: distributor,
                       delivery_service: delivery_services.sample,
                       first_name: Faker::Name.name
                      )
  customer.tag_list = random_tag_list
  customer.save!
  account = customer.account
  account.change_balance_to!(RANDOM_BALANCE.rand(-999..999))
  account.save!
end
