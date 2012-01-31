module FabricationHelper
  def order_with_deliveries
    @distributor = Fabricate(:distributor)
    @route = Fabricate(:route, :distributor => @distributor)
    @box = Fabricate(:box, :distributor => @distributor)

    @order = Fabricate(:recurring_order, :box => @box, :completed => true)
    @order
  end

end
