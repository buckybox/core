module FabricationHelper
  #TODO : refactor this away
  def order_with_deliveries
    Fabricate(:recurring_order, :completed => true, :active => true)
  end

end
