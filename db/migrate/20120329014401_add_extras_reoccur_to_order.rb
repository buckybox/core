class AddExtrasReoccurToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :extras_reoccur, :boolean

  end
end
