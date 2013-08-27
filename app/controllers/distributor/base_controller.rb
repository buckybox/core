class Distributor::BaseController < ApplicationController
  layout 'distributor'

  before_filter :authenticate_distributor!
  before_filter :mark_seen_recently
  before_filter :get_notifications

  skip_after_filter :intercom_rails_auto_include

private

  def mark_seen_recently
    current_distributor.mark_seen_recently! if current_distributor.present? && !current_admin.present?
  end

  def get_notifications
    @notifications ||= Event.all_for_distributor(current_distributor)
  end
end
