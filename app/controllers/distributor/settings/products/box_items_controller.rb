class Distributor::Settings::Products::BoxItemsController < Distributor::BaseController
  def show
    render_form
  end

private

  def render_form
    @line_items = current_distributor.line_items.decorate
    @line_items.unshift(LineItem.new.decorate) # new box item

    render 'distributor/settings/products/box_items', locals: {
      line_items: @line_items,
    }
  end
end

