class Distributor::BaseController < ApplicationController
  before_filter :authenticate_distributor!
  before_filter :mark_seen_recently
  before_filter :get_notifications
  layout 'distributor'

private

  def mark_seen_recently
    current_distributor.mark_seen_recently! if current_distributor.present? && !current_admin.present?
  end

  def get_notifications
    @notifications = Event.remove_duplicates(current_distributor.events.active.current.scoped.includes(:customer, :delivery, :transaction))
  end
end
