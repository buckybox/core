class RemoveDistributorGateway < ActiveRecord::Migration
  def up
    drop_table :distributor_gateways
  end
end
