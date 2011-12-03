class AddTelephoneNumberToInvoiceInformation < ActiveRecord::Migration
  def change
    add_column :invoice_information, :phone, :string
  end
end
