class Admin::CronLogsController < Admin::BaseController
  def index
    @cron_logs = CronLog.where("created_at > ?", 2.days.ago)
  end
end
