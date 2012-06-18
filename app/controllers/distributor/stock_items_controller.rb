class Distributor::StockItemsController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  def create
    create! { distributor_items_url }
  end

  def update
    update! { distributor_items_url }
  end
end
