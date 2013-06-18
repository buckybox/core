class Distributor::SessionsController < Devise::SessionsController
  def new
    analytical.event('view_distributor_sign_in')
    super
  end

  def create
    analytical.event('distributor_signed_in')

    result = super

    DistributorLogin.track(current_distributor)

    # macro event (acquisition)
    usercycle.event(current_distributor, 'signed_up', {
      company: current_distributor.name,
      email: current_distributor.email,
      first_name: current_distributor.contact_name
    })

    result
  end
end

