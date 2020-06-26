class AddNextOccurrenceFunction < ActiveRecord::Migration
  def up
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
  rescue Errno::ENOENT => e
    warn "Skipping migration: #{e}"
  end

  def down
    # Create drop statements from above file
    execute File.read(File.join(Bucky::Sql::PATH, 'next_occurrence.pgsql'))
      .scan(/CREATE OR REPLACE FUNCTION [a-z_]+\([^\)]+\)/).collect do |block|
      block.gsub(/CREATE OR REPLACE FUNCTION/i, "DROP FUNCTION IF EXISTS")
    end.join(";")
  end
end
