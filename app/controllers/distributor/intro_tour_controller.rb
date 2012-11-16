class Distributor::IntroTourController < Distributor::BaseController
  def dismiss
    intro_tour_name = "#{params[:tour_type]}_intro"

    if Distributor.column_names.include?(intro_tour_name)
      updated = current_distributor.update_attribute(intro_tour_name, false)
    end

    if updated
      head :ok
    else
      head :bad_request
    end
  end
end
