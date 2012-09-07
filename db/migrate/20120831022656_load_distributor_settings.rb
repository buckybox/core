class LoadDistributorSettings < ActiveRecord::Migration
  class Country < ActiveRecord::Base; end
  class Distributor < ActiveRecord::Base; end

  require 'csv'
  def up
    Country.reset_column_information

    Country.transaction do
      CSV.parse(csv, headers: true) do |row|
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

  def csv
    <<CSV
"Country Name","Currency","Default Time Zone","Default Consumer Fee"
"US","USD","Pacific Time (US & Canada)",0.1
"AU","AUD","Sydney",0.1
"NZ","NZD","Auckland",0.1
"UK","GBP","London",0.1
"Spain","EUR","Madrid",0.1
"HK","HKD","Hong Kong",1
"Europe","EUR","London",0.1
"Argentina","ARS","Buenos Aires",0.25
"Turkey","TRY","Istanbul",0.1
"Thailand","THB","Bangkok",1
"China","CNY","Beijing",0.1
"India","INR","New Delhi",1
"Mexico","MXN","Mexico City",0.5
CSV
  end
end
