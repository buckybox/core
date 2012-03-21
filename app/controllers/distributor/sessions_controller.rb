class Distributor::SessionsController < Devise::SessionsController
  def new
    analytical.event('view_distributor_sign_in')
    super
  end

  def create
    analytical.event('distributor_signed_in')
    super
  end
end

