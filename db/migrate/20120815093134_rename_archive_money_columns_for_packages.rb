class RenameArchiveMoneyColumnsForPackages < ActiveRecord::Migration
  def up
    rename_column :packages, :archived_price_cents, :archived_box_price_cents
    rename_column :packages, :archived_fee_cents, :archived_route_fee_cents
  end

  def down
    rename_column :packages, :archived_route_fee_cents, :archived_fee_cents
    rename_column :packages, :archived_box_price_cents, :archived_price_cents
  end
end
