class CreateDistributorsOmniImporters < ActiveRecord::Migration
  def change
    create_table :distributors_omni_importers do |t|
      t.integer :distributor_id
      t.integer :omni_importer_id

      t.timestamps
    end
  end
end
