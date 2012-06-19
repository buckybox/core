class Distributor::StockItemsController < Distributor::ResourceController
  actions :all, only: :create

  respond_to :html, :xml, :json

  def create
     if StockItem.from_list!(current_distributor, params[:stock_list][:names])
       flash[:notice] = 'The stock list was successfully updated.'
       redirect_to distributor_settings_stock_list_url
     else
       flash[:error] = 'Could not update the stock list.'
       redirect_to distributor_settings_stock_list_url
     end
  end
end
