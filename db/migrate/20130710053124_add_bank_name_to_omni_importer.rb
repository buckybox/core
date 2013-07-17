class AddBankNameToOmniImporter < ActiveRecord::Migration
  def up
    add_column :omni_importers, :bank_name, :string

    OmniImporter.all.each do |omni|
      bank_name = omni.name

      # strip date format
      %w(HSBC Westpac).each do |bank|
        bank_name = bank if bank_name.start_with? bank
      end

      omni.update_attributes(bank_name: bank_name)
    end
  end

  def down
    remove_column :omni_importers, :bank_name
  end
end
