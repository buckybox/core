class UpdateNextOccurrenceDbFunction < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  rescue Errno::ENOENT => e
    warn "Skipping migration: #{e}"
  end

  def down
  end
end
