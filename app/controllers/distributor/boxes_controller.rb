class Distributor::BoxesController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]

  def filter_params
    params[:box] = params[:box].slice!(:extra_option)
  end

  def create
    create! { distributor_settings_boxes_url }
  end

  def update
    update! { distributor_settings_boxes_url }
  end
end
