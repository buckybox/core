class Admin::DistributorsController <  Admin::BaseController
  defaults :route_prefix => 'admin'

  def impersonate
    distributor = Distributor.find(params[:id])
    sign_in(distributor)
    redirect_to distributor_root_path
  end

  def unimpersonate
    sign_out(:distributor)
    redirect_to admin_root_path
  end
end
