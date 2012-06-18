class Distributor::StockItemsController < Distributor::ResourceController
  actions :all, only: :create

  respond_to :html, :xml, :json

  def create
     if StockItem.from_list!(current_distributor, params[:stock_list][:names])
       redirect_to distributor_settings_stock_list_url
     else
       flash[:error] = 'Could not make the stock list.'
       redirect_to distributor_settings_stock_list
     end
  end
end
