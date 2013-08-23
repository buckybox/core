class Distributor::BoxesController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]

  def create
    create! { distributor_settings_boxes_url }
    tracking.event(current_distributor, 'new_box') unless current_admin.present?
  end

  def update
    update! { distributor_settings_boxes_url }
  end

  # No show page, so redirect to edit
  def show
    show! do |format|
      format.html do
        redirect_to edit_distributor_box_path(params[:id])
      end
    end
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
