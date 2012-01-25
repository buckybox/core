class Distributor::OrdersController < Distributor::BaseController
  nested_belongs_to :customer
  actions :all, :except => :index

  respond_to :html, :xml, :json

  def first
    raise 'jbv'
  end

  def update
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:account_id])
    @order = Order.find(params[:id])

    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update! { [current_distributor, @account] }
  end
end
