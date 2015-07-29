class Distributor::DistributorsController < Distributor::BaseController
  def update
    if current_distributor.update_attributes(params[:distributor])
      redirect_to distributor_settings_organisation_path, notice: "Organisation was successfully updated"
    else
      render 'distributor/settings/organisation', error: "Could not update organisation"
    end
  end
end
