class ApplicationController < ActionController::Base
  protect_from_forgery

  unless Rails.env.development?
    analytical :modules=>[:google, :kiss_metrics], :use_session_store=>true
  else
    analytical :modules=>[], :use_session_store=>true
  end

  before_filter :set_user_time_zone

  private

  def set_user_time_zone
    distributor = current_distributor || current_customer.distributor
    if distributor.present? && distributor.time_zone.present?
      Time.zone = distributor.time_zone 
    else
      Time.zone = BuckyBox::Application.config.time_zone
    end
  end
end
