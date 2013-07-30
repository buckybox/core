class UpdateDefaultConsumerFeeCentsForCountry < ActiveRecord::Migration
  def change
    change_column :countries, :default_consumer_fee_cents, :integer, default: 0, null: false
  end
end
