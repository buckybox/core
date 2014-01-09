module DistributorHelper
  COLLECT_BOOLEANS = {
    "phone numbers"    => "collect_phone",
    "a delivery note"  => "collect_delivery_note",
  }

  def collect_options(human_name, value = true)
    attribute = collect_boolean(human_name)
    attribute ? { attribute.to_sym => value } : {}
  end

private

  def collect_boolean(human_name)
    COLLECT_BOOLEANS[human_name]
  end

end

World(DistributorHelper)
