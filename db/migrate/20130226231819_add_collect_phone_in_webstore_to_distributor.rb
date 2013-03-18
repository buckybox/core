class AddCollectPhoneInWebstoreToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :collect_phone_in_webstore, :boolean
  end
end
