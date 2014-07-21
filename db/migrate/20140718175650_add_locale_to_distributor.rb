class AddLocaleToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :locale, :string, null: false, default: :en
  end
end
