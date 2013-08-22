class RemoveCurrencyFromModels < ActiveRecord::Migration
  def change
    remove_column :boxes,             :currency
    remove_column :deductions,        :currency
    remove_column :extras,            :currency
    remove_column :invoices,          :currency
    remove_column :packages,          :currency
    remove_column :payments,          :currency
    remove_column :delivery_services, :currency
    remove_column :transactions,      :currency
  end
end
