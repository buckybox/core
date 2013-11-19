class Distributor::Settings::Products::ExtraItemsController < Distributor::BaseController
  def show
    render_form
  end

  def create
    extra_params = params[:extra]

    extra = Extra.new(extra_params)
    extra.distributor = current_distributor

    if extra.save
      flash.now[:notice] = "Your new extra item has heen created."
    else
      flash.now[:error] = extra.errors.full_messages.to_sentence
    end

    render_form
  end

  def update
    extra_params = params[:extra]
    extra = current_distributor.extras.find(extra_params.delete(:id))

    if extra.update_attributes(extra_params)
      flash.now[:notice] = "Your extra item has heen updated."
    else
      flash.now[:error] = extra.errors.full_messages.to_sentence
    end

    render_form
  end

private

  def render_form
    @extras = current_distributor.extras.alphabetically.decorate
    @extras.unshift(Extra.new.decorate) # new extra

    render 'distributor/settings/products/extra_items', locals: {
      extras: @extras,
    }
  end
end

