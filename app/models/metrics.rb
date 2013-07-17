class Metrics
  MUNIN_METRICS_FILE = Rails.root.join("log/munin_metrics")
  MUNIN_METRICS_CONFIG_FILE = Rails.root.join("log/munin_metrics.config")

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

  def self.calculate_and_store_for_munin
    metrics = {
      "new_distributors_last_7_days" => -> {
        Distributor.where("created_at > ?", 7.day.ago).count
      },
      "new_customers_last_7_days" => -> {
        Customer.where("created_at > ?", 7.day.ago).count
      },
      "delivered_deliveries_last_day" => -> {
        Delivery.delivered.where("updated_at > ?", 1.day.ago).count
      }
    }

    File.open(MUNIN_METRICS_CONFIG_FILE, "w") do |file|
      file.puts <<CONFIG
graph_category Bucky
graph_title stats
graph_vlabel count
graph_info This graph shows custom metrics about Bucky Box app.
new_distributors_last_7_days.label new distributors
new_distributors_last_7_days.draw LINE2
new_distributors_last_7_days.info The number of new distributors in the last 7 days.
new_customers_last_7_days.label new customers
new_customers_last_7_days.draw LINE2
new_customers_last_7_days.info The number of new customers in the last 7 days.
delivered_deliveries_last_day.label delivered deliveries
delivered_deliveries_last_day.draw LINE2
delivered_deliveries_last_day.info The number of delivered deliveries in the last 24 hours.
CONFIG
    end

    File.open(MUNIN_METRICS_FILE, "w") do |file|
      raw_metrics = metrics.map do |key, metric|
        "#{key}.value #{metric.call}"
      end.join("\n")

      file.puts raw_metrics
    end
  end
end
