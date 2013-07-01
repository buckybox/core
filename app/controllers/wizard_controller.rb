class WizardController < ApplicationController
  layout 'wizard'

  def form
    country = Bucky::Geolocation.get_country(request.remote_ip)
    country = "New Zealand" if country.blank? || country == "Reserved"

    time_zone = Bucky::Geolocation.get_time_zone(country)

    render :form, locals: { country: country, time_zone: time_zone }
  end

  def sign_up
    p params
    render json: nil
  end
end

