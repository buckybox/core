class Distributor::Settings::Products::ExtrasController < Distributor::BaseController
  def show
    render_form
  end

private

  def render_form
    @extras = current_distributor.extras.decorate
    @extras.unshift(Extra.new.decorate) # new extra

    render 'distributor/settings/products/extras', locals: {
      extras: @extras,
    }
  end
end

