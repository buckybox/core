class CreateInvoiceInformation < ActiveRecord::Migration
  def change
    create_table :invoice_information do |t|
      t.references :distributor
      t.string :gst_number
      t.string :billing_address_1
      t.string :billing_address_2
      t.string :billing_suburb
      t.string :billing_city
      t.string :billing_postcode

      t.timestamps
    end
    add_index :invoice_information, :distributor_id
  end
end
