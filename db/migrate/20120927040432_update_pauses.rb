class UpdatePauses < ActiveRecord::Migration
  # The SchedulePauses in the system don't respect the 366 days, so clean them out and replace them with ones that do
  def up
    ScheduleRule.delete_all
    SchedulePause.delete_all

    ScheduleRule.copy_from_ice
  rescue #if the models have changed, don't freak out
  end

  def down
  end
end
