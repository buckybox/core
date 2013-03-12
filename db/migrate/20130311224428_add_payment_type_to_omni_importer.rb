class AddPaymentTypeToOmniImporter < ActiveRecord::Migration
  def change
    add_column :omni_importers, :payment_type, :string
    remove_column :omni_importers, :global
  end
end
