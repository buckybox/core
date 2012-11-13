class AddFullNameToCountry < ActiveRecord::Migration
  def up
    add_column :countries, :full_name, :string
    Country.reset_column_information
    [[1, 'United States'],[2, 'Australia'], [3, 'New Zealand'], [6, 'Hong Kong'], [4, 'United Kingdom']].each do |id, full_name|
     country = Country.find_by_id(id)
     if country
       country.update_column(:full_name, full_name)
     end
    end
  end
end
