class CronLog < ActiveRecord::Base
  attr_accessible :log

  default_scope order('created_at DESC')

  def self.log(text)
    CronLog.create(log: text)
  end
end
