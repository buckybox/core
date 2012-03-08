class CronLog < ActiveRecord::Base
  attr_accessible :log

  def self.log(text)
    CronLog.create(log: text)
  end
end
