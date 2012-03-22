class Admin::DistributorsController < Admin::ResourceController
  def impersonate
    distributor = Distributor.find(params[:id])
    sign_in(distributor)

    redirect_to distributor_root_url
  end

  def unimpersonate
    sign_out(:distributor)

    redirect_to admin_root_url
  end
end
