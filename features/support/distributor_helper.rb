module DistributorHelper
  COLLECT_BOOLEANS = {
    "phone numbers"    => "collect_phone",
    "a delivery note"  => "collect_delivery_note",
  }

  REQUIRE_BOOLEANS = {
    "phone number" => "require_phone",
  }

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
    collect_attribute = collect_boolean(human_name)
    require_attribute = require_boolean(human_name)
    attribute ? { collect_attribute.to_sym => value, require_attribute.to_sym => value } : {}
  end

private

  def collect_boolean(human_name)
    COLLECT_BOOLEANS[human_name]
  end

  def require_boolean(human_name)
    REQUIRE_BOOLEANS[human_name]
  end

end

World(DistributorHelper)
