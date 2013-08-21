# Keeps track of customer logins
class CustomerLogin < ActiveRecord::Base
  attr_accessible :customer, :distributor_id

  belongs_to :distributor
  belongs_to :customer

  def self.track(customer)
    CustomerLogin.create!(customer: customer, distributor_id: customer.distributor_id)
  rescue StandardError => ex
    Airbrake.notify(ex)
    raise ex unless Rails.env.production?
  end
end
