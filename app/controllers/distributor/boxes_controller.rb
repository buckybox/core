class Distributor::BoxesController < Distributor::BaseController
  respond_to :json

  def show
    box = current_distributor.boxes.find(params[:id])

    respond_with box
  end

  def extras
    account = current_distributor.accounts.find_by_id(params[:account_id])
    order = Order.new
    box = current_distributor.boxes.find_by_id(params[:id]) || Box.new

    render partial: 'distributor/orders/extras', locals: { account: account, order: order, box: box }
  end
end

