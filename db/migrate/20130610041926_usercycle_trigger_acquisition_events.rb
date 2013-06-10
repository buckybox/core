class UsercycleTriggerAcquisitionEvents < ActiveRecord::Migration
  def up
    Distributor.all.each do |distributor|
      Bucky::Usercycle.instance.event(distributor, 'signed_up', {}, distributor.created_at)
    end
  end

  def down
    # noop
  end
end
