class AddRequireDeliveryNoteToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :require_delivery_note, :boolean, default: false, null: false
  end
end
