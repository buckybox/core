class Distributor::SessionsController < Devise::SessionsController
  def new
    analytical.event('view_distributor_sign_in')
    super
  end

  def create
    analytical.event('distributor_signed_in')

    result = super

    if DistributorLogin.first?(current_distributor)
      usercycle.event(current_distributor, 'signed_up') # acquisition event
    end

    DistributorLogin.track(current_distributor)

    result
  end
end

