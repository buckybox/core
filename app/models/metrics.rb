class Metrics
  MUNIN_DAILY_METRICS_FILE = Rails.root.join("log/munin_daily_metrics")
  MUNIN_DAILY_METRICS_CONFIG_FILE = Rails.root.join("log/munin_daily_metrics.config")

  MUNIN_WEEKLY_METRICS_FILE = Rails.root.join("log/munin_weekly_metrics")
  MUNIN_WEEKLY_METRICS_CONFIG_FILE = Rails.root.join("log/munin_weekly_metrics.config")

  def self.calculate_and_store
    count = 0
    Distributor.find_each do |distributor|
      metric = distributor.distributor_metrics.new
      metric.distributor_logins = distributor.distributor_logins.where(time_frame('distributor_logins')).count
      metric.new_customers = distributor.customers.where(time_frame('customers')).count
      metric.deliveries_completed = distributor.deliveries.delivered.where(time_frame('deliveries')).count
      metric.customer_payments = distributor.payments.import.where(time_frame('payments')).count
      metric.webstore_checkouts = distributor.customer_checkouts.where(time_frame('customer_checkouts')).count
      metric.customer_logins = distributor.customer_logins.where(time_frame('customer_logins')).count
      metric.save!
      count += 1
    end
    count
  end

  def self.time_frame(table)
    beginning_of_yesterday = (Time.current - 24.hours).beginning_of_day
    end_of_yesterday = (Time.current - 24.hours).end_of_day
    ["#{table}.created_at > ? AND #{table}.created_at <= ?", beginning_of_yesterday, end_of_yesterday]
  end

  def self.calculate_and_store_for_munin
    calculate_and_store_for_munin_daily
    calculate_and_store_for_munin_weekly
  end

  def self.calculate_and_push_to_librato
    return unless Rails.env.production?

    config = YAML.load_file(Rails.root.join("config/librato.yml"))["production"]

    Librato::Metrics.authenticate config.fetch("user"), config.fetch("token")

    queue = Librato::Metrics::Queue.new(source: config.fetch("source"))

    queue.add "bucky.distributor.total" => Distributor.count
    queue.add "bucky.distributor.active" => Distributor.active.count
    queue.add "bucky.webstore.active" => Distributor.active_webstore.active.count
    queue.add "bucky.customer.transactional.new_last_7_days" => Distributor.all.sum(&:new_transactional_customer_count)
    queue.add "bucky.customer.active" => Customer.active.count

    queue.submit
  end

private

  def self.calculate_and_store_for_munin_daily
    now = Time.zone.now
    last_24_hours = (now - 24.hours)..now

    classes = [Order, Delivery, Deduction, Payment, Transaction, Customer, Distributor, ImportTransactionList].inject({}) do |hash, klass|
      hash.merge!(klass.name.pluralize.downcase => klass)
    end

    metrics = classes.inject({}) do |hash, (key, klass)|
      metric_key = "new_#{key}_last_24_hours"

      hash.merge!(metric_key => lambda {
        klass.where(created_at: last_24_hours).count
      })
    end

    File.open(MUNIN_DAILY_METRICS_CONFIG_FILE, "w") do |file|
      file.puts <<CONFIG
graph_category Bucky
graph_title daily stats
graph_vlabel count
graph_info This graph shows custom metrics about Bucky Box app.
CONFIG
      classes.each do |key, klass|
        file.puts <<CONFIG
new_#{key}_last_24_hours.label new #{key}
new_#{key}_last_24_hours.draw LINE2
new_#{key}_last_24_hours.info The number of new #{klass.name.pluralize} in the last 7 days.
CONFIG
      end
    end

    File.open(MUNIN_DAILY_METRICS_FILE, "w") do |file|
      raw_metrics = metrics.map do |key, metric|
        "#{key}.value #{metric.call}"
      end.join("\n")

      file.puts raw_metrics
    end
  end

  def self.calculate_and_store_for_munin_weekly
    now = Time.zone.now
    last_7_days = (now - 7.days)..now

    metrics = {
      "new_distributors_last_7_days" => lambda {
        Distributor.where(created_at: last_7_days).count
      },
      "new_transactional_customers_last_7_days" => lambda {
        Distributor.all.map(&:new_transactional_customer_count).sum
      },
    }

    File.open(MUNIN_WEEKLY_METRICS_CONFIG_FILE, "w") do |file|
      file.puts <<CONFIG
graph_category Bucky
graph_title weekly stats
graph_vlabel count
graph_info This graph shows custom metrics about Bucky Box app.
new_distributors_last_7_days.label new distributors
new_distributors_last_7_days.draw LINE2
new_distributors_last_7_days.info The number of new distributors in the last 7 days.
new_transactional_customers_last_7_days.label new transactional customers
new_transactional_customers_last_7_days.draw LINE2
new_transactional_customers_last_7_days.info The number of new transactional customers in the last 7 days.
CONFIG
    end

    File.open(MUNIN_WEEKLY_METRICS_FILE, "w") do |file|
      raw_metrics = metrics.map do |key, metric|
        "#{key}.value #{metric.call}"
      end.join("\n")

      file.puts raw_metrics
    end
  end
end
