class Distributor::NotificationsController < Distributor::BaseController
  def dismiss_all
    current_distributor.events.where(id: params[:notification_ids])
    notifications.each(&:dismiss!)

    redirect_to :back
  end
end
