class Distributor::Settings::Products::BoxesController < Distributor::BaseController
  before_filter :fetch_box_params, only: [:create, :update]

  def show
    render_form
  end

  def create
    box = Box.new(@box_params)
    box.distributor = current_distributor

    if box.save
      tracking.event(current_distributor, 'new_box') unless current_admin.present?
      flash.now[:notice] = "Your new box has heen created."
    else
      flash.now[:error] = box.errors.full_messages.to_sentence
    end

    render_form
  end

  def update
    box = current_distributor.boxes.find(params[:box][:id])

    if box.update_attributes(@box_params)
      flash.now[:notice] = "Your box has heen updated."
    else
      flash.now[:error] = box.errors.full_messages.to_sentence
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

  def fetch_box_params
    @box_params = params[:box]

    if @box_params.delete(:extras_allowed).to_i.zero?
      @box_params[:extras_limit] = 0
    end

    unless @box_params.delete(:all_extras).to_i.zero?
      @box_params[:extra_ids] = current_distributor.extra_ids
    end
  end
end

