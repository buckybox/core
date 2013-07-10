class AddBankNameToOmniImporter < ActiveRecord::Migration
  def up
    add_column :omni_importers, :bank_name, :string

    OmniImporter.all.each do |omni|
      bank_name = omni.name

      # strip date format for Westpac
      bank_name = "Westpac" if bank_name.start_with? "Westpac"

      omni.update_attributes(bank_name: bank_name)
    end
  end

  def down
    remove_column :omni_importers, :bank_name
  end
end
