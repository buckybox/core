class Distributor::DashboardController < Distributor::BaseController
  def index
    @events   = current_distributor.events.active.current
    @payments = current_distributor.payments.manual.order('created_at DESC').limit(10)
    @payment  = current_distributor.payments.new(source: 'manual')
    @accounts = current_distributor.accounts.includes(:customer).sort { |a,b| a.customer.name <=> b.customer.name }
  end

  def dismiss_event
    if Event.find(params[:id]).dismiss!
      head :ok
    else
      head :bad_request
    end
  end
end
