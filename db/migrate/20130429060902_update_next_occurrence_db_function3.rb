class UpdateNextOccurrenceDbFunction3 < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  end

  def down
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence_v3.pgsql'))
  end
end
