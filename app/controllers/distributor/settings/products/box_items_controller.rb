class Distributor::Settings::Products::BoxItemsController < Distributor::BaseController
  def show
    render_form
  end

  def update
    new_line_items = params[:new_line_items]
    line_items = params[:line_items]

    if !LineItem.from_list(current_distributor, new_line_items).nil? && LineItem.bulk_update(current_distributor, line_items)
      flash[:notice] = 'The box items were successfully updated.'
    else
      flash[:error] = 'Oops, could not update your box items.'
    end

    render_form
  end

private

  def render_form
    @line_items = current_distributor.line_items.decorate

    render 'distributor/settings/products/box_items', locals: {
      line_items: @line_items,
    }
  end
end

