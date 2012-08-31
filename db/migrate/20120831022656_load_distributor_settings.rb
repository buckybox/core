class LoadDistributorSettings < ActiveRecord::Migration
  class Country < ActiveRecord::Base; end
  class Distributor < ActiveRecord::Base; end

  require 'csv'
  def up
    Country.reset_column_information

    Country.transaction do
      CSV.foreach(File.join(Rails.root,"config/distributor_settings.csv"), headers: true) do |row|
        country = Country.find_by_name(row['Country Name']) || Country.new
        country.attributes = {name: row['Country Name'],
                      default_currency: row['Currency'],
                      default_time_zone: row['Default Time Zone'],
                      default_consumer_fee_cents: row['Default Consumer Fee'].to_f * 100}
        country.save!
      end
    end
    
    Distributor.reset_column_information
    Distributor.update_all({separate_bucky_fee: false, consumer_delivery_fee_cents: 10})
  end

  def down
  end
end
