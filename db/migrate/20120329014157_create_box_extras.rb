class CreateBoxExtras < ActiveRecord::Migration
  def change
    create_table :box_extras do |t|
      t.integer :box_id
      t.integer :extra_id

      t.timestamps
    end
  end
end
