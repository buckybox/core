class Distributor::Settings::Payments::BaseController < Distributor::BaseController
  def track
    tracking.event(current_distributor, "new_bank_information") unless current_admin.present?
  end
end

