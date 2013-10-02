class Distributor::Settings::Products::ExtraItemsController < Distributor::BaseController
  def show
    render_form
  end

private

  def render_form
    @extras = current_distributor.extras.decorate
    @extras.unshift(Extra.new.decorate) # new extra

    render 'distributor/settings/products/extra_items', locals: {
      extras: @extras,
    }
  end
end

