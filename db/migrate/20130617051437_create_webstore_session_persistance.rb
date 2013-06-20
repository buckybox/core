class CreateWebstoreSessionPersistance < ActiveRecord::Migration
  def change
    create_table :webstore_session_persistances do |t|
      t.text :collected_data

      t.timestamps
    end
  end
end
