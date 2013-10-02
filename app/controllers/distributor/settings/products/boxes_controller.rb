class Distributor::Settings::Products::BoxesController < Distributor::BaseController
  def show
    render_form
  end

  def create
    box_params = params[:box]

    # FIXME
    box_params.delete(:all_extras)
    box_params.delete(:extras)

    box = Box.new(box_params)

    if box.save
      flash.now[:notice] = "Your new box has heen created."
    end

    render_form
  end

  def update
    box_params = params[:box]
    box = current_distributor.boxes.find(box_params.delete(:id))

    # FIXME
    box_params.delete(:all_extras)
    box_params.delete(:extras)

    if box.update_attributes(box_params)
      flash.now[:notice] = "Your box has heen updated."
    end

    render_form
  end

private

  def render_form
    @boxes = current_distributor.boxes.decorate
    @boxes.unshift(Box.new.decorate) # new box

    render 'distributor/settings/products/boxes', locals: {
      boxes: @boxes,
    }
  end
end

