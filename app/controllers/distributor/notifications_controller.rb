class Distributor::NotificationsController < Distributor::BaseController
  def dismiss_all
    notifications = Event.find_all_by_id(params[:notification_ids])
    notifications.each { |notification| notification.dismiss! }

    redirect_to :back
  end
end
