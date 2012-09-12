class UpdateDistributorCountry < ActiveRecord::Migration
  def up
    Distributor.reset_column_information
    Distributor.transaction do
      [[2, 'NZ'], [14, 'AU'], [15, "NZ"]].each do |id, c_code|
        distributor = Distributor.find_by_id(id)
        country = Country.find_by_name(c_code)
        if distributor && country
          distributor.country = country
          distributor.save!
        end
      end
    end
  end

  def down
  end
end
