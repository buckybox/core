class DistributorDefaults
  def self.populate_defaults(distributor)
    LineItem.add_defaults_to(distributor)
  end
end
