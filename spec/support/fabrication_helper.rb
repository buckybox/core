module FabricationHelper
  def order_with_deliveries
    @distributor = Fabricate(:distributor)
    @route = Fabricate(:route, :distributor => @distributor)
    @order = Fabricate(:recurring_order, :distributor => @distributor, :completed => true)
    @order
  end

end
