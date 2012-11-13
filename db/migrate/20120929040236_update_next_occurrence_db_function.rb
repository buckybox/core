class UpdateNextOccurrenceDbFunction < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  end

  def down
  end
end
