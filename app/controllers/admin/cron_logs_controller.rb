class Admin::CronLogsController < Admin::ResourceController
  actions :index

  protected

  def collection
    @cron_logs ||= end_of_association_chain.where("created_at > ?", 2.days.ago)
  end
end

