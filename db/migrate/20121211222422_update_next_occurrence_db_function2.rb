class UpdateNextOccurrenceDbFunction2 < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  rescue Errno::ENOENT => e
    warn "Skipping migration: #{e}"
  end

  def down
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence_v2.pgsql'))
  end
end
