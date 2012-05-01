class ApplicationController < ActionController::Base
  protect_from_forgery

  unless Rails.env.development?
    analytical :modules=>[:google, :kiss_metrics], :use_session_store=>true
  else
    analytical :modules=>[], :use_session_store=>true
  end

  around_filter :hack_time if Rails.env.development?
  before_filter :set_user_time_zone
  before_filter :set_user_currency

  private

  def hack_time
    past = params.delete(:time_travel_to)

    @@past ||= nil
    @@past = past unless past.blank?

    if @@past.blank?
      yield
    else
      Delorean.time_travel_to(@@past) do
        flash.now[:alert] =  "Time is now #{Time.current}"
        yield
      end
    end
  end

  def set_user_time_zone
    distributor = current_distributor || current_customer.try(:distributor)

    if distributor.present? && distributor.time_zone.present?
      Time.zone = distributor.time_zone
    else
      Time.zone = BuckyBox::Application.config.time_zone
    end
  end

  def set_user_currency
    distributor = current_distributor || current_customer.try(:distributor)

    if distributor.present? && distributor.currency.present?
      Money.default_currency = Money::Currency.new(distributor.currency)
    end
  end
end
