class Distributor::BoxesController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]

  def create
    create! { distributor_settings_boxes_url }
  end

  def update
    update! { distributor_settings_boxes_url }
  end

  def extras
    account = current_distributor.accounts.find_by_id(params[:account_id])
    order = Order.new
    box = current_distributor.boxes.find_by_id(params[:id]) || Box.new

    render partial: 'distributor/orders/extras', locals: { account: account, order: order, box: box }
  end

  private

  def filter_params
    params[:box] = params[:box].slice!(:all_extras)
  end
end
