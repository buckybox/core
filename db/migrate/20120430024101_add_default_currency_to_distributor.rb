class AddDefaultCurrencyToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :currency, :string
  end
end
