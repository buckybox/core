class Distributor::LineItemsController < Distributor::ResourceController
  actions :all, only: :create

  respond_to :html, :xml, :json

  def create
    if LineItem.from_list(current_distributor, params[:stock_list][:names])
      tracking.event(current_distributor, "new_stock_item") unless current_admin.present?

      flash[:notice] = 'The customer preferences were successfully updated.'
      redirect_to distributor_settings_customer_preferences_url
    else
      flash[:error] = 'Could not update the customer preferences.'
      redirect_to distributor_settings_customer_preferences_url(edit: true)
    end
  end

  def bulk_update
    line_items = params[:line][:items]if params[:line].present?

    if LineItem.bulk_update(current_distributor, line_items)
      flash[:notice] = 'The customer preferences were successfully updated.'
      redirect_to distributor_settings_customer_preferences_url
    else
      flash[:error] = 'Could not update the customer preferences.'
      redirect_to distributor_settings_customer_preferences_url(edit: true)
    end
  end
end
