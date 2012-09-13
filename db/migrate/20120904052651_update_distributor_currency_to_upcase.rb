class UpdateDistributorCurrencyToUpcase < ActiveRecord::Migration
  def up
    Distributor.reset_column_information
    Distributor.transaction do
      Distributor.all.each do |d|
        d.currency = d.currency.upcase
        d.save!
      end
    end
  end

  def down
  end
end
