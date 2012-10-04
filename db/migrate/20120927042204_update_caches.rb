class UpdateCaches < ActiveRecord::Migration
  def up
    # Now that ice cube is up to date, run the caches again
    Distributor.find_each do |distributor|
      distributor.update_next_occurrence_caches
    end
  end

  def down
  end
end
