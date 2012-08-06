class Distributor::LineItemsController < Distributor::ResourceController
  actions :all, only: :create

  respond_to :html, :xml, :json

  def create
    if LineItem.from_list(current_distributor, params[:stock_list][:names])
      flash[:notice] = 'The stock list was successfully updated.'
      redirect_to distributor_settings_stock_list_url
    else
      flash[:error] = 'Could not update the stock list.'
      redirect_to distributor_settings_stock_list_url(edit: true)
    end
  end

  def bulk_update
    if LineItem.bulk_update(current_distributor, params[:line][:items])
      flash[:notice] = 'The stock list was successfully updated.'
      redirect_to distributor_settings_stock_list_url
    else
      flash[:error] = 'Could not update the stock list.'
      redirect_to distributor_settings_stock_list_url(edit: true)
    end
  end
end
