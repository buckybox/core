class ApplicationController < ActionController::Base
  protect_from_forgery

  unless Rails.env.development?
    analytical modules: [:google, :kiss_metrics], use_session_store: true
  else
    analytical modules: [], use_session_store: true
  end

  around_filter :hack_time if Rails.env.development?
  before_filter :set_user_time_zone
  before_filter :set_user_currency

  layout :layout_by_resource

  rescue_from Postmark::InvalidMessageError, with: :postmark_delivery_error
  # Taken from http://stackoverflow.com/questions/7642648/what-is-the-best-way-to-handle-email-exceptions-in-a-rails-app-using-postmarkapp

  protected

  def postmark_delivery_error(exception)
    if (address = derive_email_from_postmark_exception(exception)).present?
      #link = %Q[<a href="#{ reactivate_email_bounce_path(address)  }">reactivating</a>]
      msg = "We could not deliver a recent message to '#{ address }'. The email was disabled due to a hard bounce or a spam complaint."# You can try #{ link } it and try again."
    else
      msg = "We could not deliver a recent message. The email was disabled due to a hard bounce or a spam complaint. Please contact support."
    end
    flash[:alert] = msg
    redirect_to :back
  end

  def derive_email_from_postmark_exception(exception)
    exception.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i).uniq.join(', ').strip
  end

  def layout_by_resource
    if devise_controller?
      "#{resource_name}_devise"
    else
      super
    end
  end
  
  def account_transactions(account, offset=0, limit=6, dummy=true)
    transactions = []
    if cookies["transaction_order"].blank? || cookies["transaction_order"] == 'date_processed'
      transactions = account.transactions.ordered_by_created_at.limit(limit).offset(offset)
    else
      transactions = account.transactions.ordered_by_display_time.limit(limit).offset(offset)
    end
    transactions = [Transaction.dummy(0, "Opening Balance", @account.created_at)] if transactions.empty? && dummy
    transactions
  end

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

  def after_sign_out_path_for(resource_or_scope)
    # Clear? No? Oh, that's weird for this app. :S

    if resource_or_scope == :admin
      admin_root_url
    elsif resource_or_scope == :distributor
      distributor_root_url
    elsif resource_or_scope == :customer
      if current_customer
        distributor_param_name = current_customer.distributor.parameter_name
      else
        request.referer =~ /\/webstore\/([^\/]+).*/
        distributor_param_name = $1
      end

      if distributor_param_name.blank?
        customer_root_url
      else
        webstore_store_url(distributor_param_name)
      end
    else
      'http://www.buckybox.com/' # Shouldn't happen but better than nothing.
    end
  end
end
