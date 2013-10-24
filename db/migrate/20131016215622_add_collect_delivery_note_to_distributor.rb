class AddCollectDeliveryNoteToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :collect_delivery_note, :boolean, default: true, null: false
  end
end
