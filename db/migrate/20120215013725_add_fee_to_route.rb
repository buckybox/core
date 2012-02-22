class AddFeeToRoute < ActiveRecord::Migration
  def change
    add_column :routes, :fee_cents, :integer, default: 0
    add_column :routes, :currency, :string
  end
end
