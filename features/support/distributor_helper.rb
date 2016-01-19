module DistributorHelper
  COLLECT_BOOLEANS = {
    "phone numbers"    => "collect_phone",
    "a delivery note"  => "collect_delivery_note",
  }.freeze

  REQUIRE_BOOLEANS = {
    "phone numbers"               => "require_phone",
    "a first line of an address"  => "require_address_1",
    "a second line of an address" => "require_address_2",
    "a suburb"                    => "require_suburb",
    "a city"                      => "require_city",
    "a postcode"                  => "require_postcode",
    "a delivery note"             => "require_delivery_note",
  }.freeze

  def customer_login_with_distributor(distributor)
    customer = distributor.customers.last
    customer.password = "Let me in!"
    customer.save!

    login_as customer
  end

  def collect_options(human_name, value = true)
    attribute = collect_boolean(human_name)
    attribute ? { attribute.to_sym => value } : {}
  end

  def require_options(human_name, value = true)
    hash = collect_options(human_name)
    require_attribute = require_boolean(human_name)
    hash[require_attribute.to_sym] = value
    hash
  end

private

  def collect_boolean(human_name)
    COLLECT_BOOLEANS.fetch(human_name, nil)
  end

  def require_boolean(human_name)
    REQUIRE_BOOLEANS.fetch(human_name)
  end
end

World(DistributorHelper)
