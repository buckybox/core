class CreateDistributorLogins < ActiveRecord::Migration
  def change
    create_table :distributor_logins do |t|
      t.integer :distributor_id

      t.timestamps
    end
  end
end
