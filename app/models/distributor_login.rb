# Keeps track of distributor logins
class DistributorLogin < ActiveRecord::Base
  attr_accessible :distributor

  belongs_to :distributor

  def self.track(distributor)
    DistributorLogin.create!(distributor: distributor)
  rescue StandardError => ex
    Airbrake.notify(ex)
    raise ex unless Rails.env.production?
  end

  def self.first?(distributor)
    where(distributor_id: distributor.id).count.zero?
  end
end
