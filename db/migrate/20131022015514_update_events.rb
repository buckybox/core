class UpdateEvents < ActiveRecord::Migration
  class Event < ActiveRecord::Base; end

  def up
    remove_column :events, :event_category
    remove_column :events, :customer_id
    remove_column :events, :invoice_id
    remove_column :events, :reconciliation_id
    remove_column :events, :transaction_id
    remove_column :events, :delivery_id

    add_column :events, :message, :text
    add_column :events, :key, :string

    Event.reset_column_information
    Event.update_all(dismissed: true)
  end

  def down
    remove_column :events, :message
    remove_column :events, :key

    add_column :events, :event_category, :string
    add_column :events, :customer_id, :integer
    add_column :events, :invoice_id, :integer
    add_column :events, :reconciliation_id, :integer
    add_column :events, :transaction_id, :integer
    add_column :events, :delivery_id, :integer
  end
end
