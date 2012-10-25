class UpdateNextOccurrenceDbFunction < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence_v2.pgsql'))
  end

  def down
    # Create drop statements from above file
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence_v2.pgsql')).
      scan(/CREATE OR REPLACE FUNCTION [a-z_]+\([^\)]+\)/).collect{|block|
      block.gsub(/CREATE OR REPLACE FUNCTION/i, "DROP FUNCTION IF EXISTS")
    }.join(";")
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  end
end
