class DistributorMetric < ActiveRecord::Base
  attr_accessible :customer_logins, :customer_payments, :deliveries_completed, :distributor_id, :distributor_logins, :new_customers, :webstore_checkouts
end
