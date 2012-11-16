class AddAndChangeIntroTourBooleansToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :customers_index_intro, :boolean, default: true, null: false
    rename_column :distributors, :payments_index_packing_intro, :payments_index_intro
  end
end
