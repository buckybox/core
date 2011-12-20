module Distributor::DashboardHelper
  def notification_text_for notification
  end

  def date_for notification
    notification.created_at.strftime("%d %B")
  end
end
