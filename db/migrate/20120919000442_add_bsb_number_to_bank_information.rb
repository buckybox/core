class AddBsbNumberToBankInformation < ActiveRecord::Migration
  def change
    add_column :bank_information, :bsb_number, :string
  end
end
