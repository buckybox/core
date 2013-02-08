class Distributor::BaseController < ApplicationController
  before_filter :authenticate_distributor!
  before_filter :get_notifications
  layout 'distributor'

  private

  def get_notifications
    @notifications = Event.remove_duplicates(current_distributor.events.active.current.scoped.includes(:customer, :delivery, :transaction))
  end
end
