class Metrics
  def self.calculate_and_store
    count = 0
    Distributor.all.each do |distributor|
      begin
        metric = distributor.distributor_metrics.new
        metric.distributor_logins = distributor.distributor_logins.where(time_frame('distributor_logins')).count
        metric.new_customers = distributor.customers.where(time_frame('customers')).count
        metric.deliveries_completed = distributor.deliveries.delivered.where(time_frame('deliveries')).count
        metric.customer_payments = distributor.payments.import.where(time_frame('payments')).count
        metric.webstore_checkouts = distributor.customer_checkouts.where(time_frame('customer_checkouts')).count
        metric.customer_logins = distributor.customer_logins.where(time_frame('customer_logins')).count
        metric.save!
        count += 1
      rescue StandardError => ex
        Airbrake.notify(ex)
        raise ex unless Rails.env.production?
      end
    end
    count
  end

  def self.time_frame(table)
    beginning_of_yesterday = (Time.current-24.hours).beginning_of_day
    end_of_yesterday = (Time.current-24.hours).end_of_day
    ["#{table}.created_at > ? AND #{table}.created_at <= ?", beginning_of_yesterday, end_of_yesterday]
  end
end
