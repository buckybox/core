module FabricationHelper
  def order_with_deliveries
    @distributor = Fabricate(:distributor)
    @route = Fabricate(:route, :distributor => @distributor)
    @order = Fabricate(:order, :distributor => @distributor, :frequency => 'weekly', :completed => true)
    @order
  end

end
