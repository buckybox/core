class RemoveGateways < ActiveRecord::Migration
  def change
    drop_table :gateways
  end
end
