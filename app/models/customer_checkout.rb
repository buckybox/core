class CustomerCheckout < ActiveRecord::Base
  attr_accessible :customer, :distributor

  belongs_to :distributor
  belongs_to :customer

  def self.track(customer, distributor)
    CustomerCheckout.create!(customer: customer, distributor: distributor)
  rescue StandardError => ex
    Airbrake.notify(ex)
    raise ex unless Rails.env.production?
  end
end
