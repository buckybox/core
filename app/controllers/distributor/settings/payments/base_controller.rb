class Distributor::Settings::Payments::BaseController < Distributor::BaseController
  def track
    current_distributor.track("new_bank_information") unless current_admin.present?
  end
end
