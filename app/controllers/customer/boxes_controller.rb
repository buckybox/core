class Customer::BoxesController < Customer::ResourceController
  actions :show

  respond_to :html, :xml, :json

  def extras
    order = Order.new
    box = current_customer.distributor.boxes.find_by_id(params[:id]) || Box.new
    render partial: 'customer/orders/extras', locals: {account: current_customer.account, order: order, box: box}
  end

  protected

  def begin_of_association_chain
    current_customer.distributor
  end
end
