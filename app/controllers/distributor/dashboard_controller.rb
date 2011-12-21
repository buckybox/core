class Distributor::DashboardController < Distributor::BaseController
  before_filter :check_wizard_completed
  before_filter :generate_notifications, :only => :index

  def index
    @notifications = current_distributor.events.active.sorted
  end

  private
  def generate_notifications
  end

  def check_wizard_completed
    current_distributor.update_attribute(:completed_wizard, params[:completed_wizard]) if params[:completed_wizard]
    redirect_to current_wizard_step and return unless current_distributor.completed_wizard?
  end

  def current_wizard_step
    if !current_distributor.name?
      distributor_wizard_business_path
    elsif current_distributor.boxes.size <= 0
      distributor_wizard_boxes_path
    elsif current_distributor.routes.size <= 0
      distributor_wizard_routes_path
    elsif !current_distributor.bank_information || !current_distributor.bank_information.account_number?
      distributor_wizard_payment_path
    elsif !current_distributor.invoice_information || !current_distributor.invoice_information.billing_address_1?
      distributor_wizard_billing_path
    else
      distributor_wizard_success_path
    end
  end
end
