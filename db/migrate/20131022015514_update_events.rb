class UpdateEvents < ActiveRecord::Migration
  def change
    remove_column :events, :event_category
    remove_column :events, :customer_id
    remove_column :events, :invoice_id
    remove_column :events, :reconciliation_id
    remove_column :events, :transaction_id
    remove_column :events, :delivery_id

    add_column :events, :message, :text
    add_column :events, :key, :string
  end
end
