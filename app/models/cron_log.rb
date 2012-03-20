class CronLog < ActiveRecord::Base
  attr_accessible :log, :details

  default_scope order('created_at DESC')

  def self.log(text, details = "")
    CronLog.create(log: text, details: details)
  end
end
