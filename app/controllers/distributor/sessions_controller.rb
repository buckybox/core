class Distributor::SessionsController < Devise::SessionsController
  def new
    analytical.event('view_distributor_sign_in')
    super
  end

  def create
    analytical.event('distributor_signed_in')

    result = super

    DistributorLogin.track(current_distributor) unless current_admin.present?

    result
  end
end

