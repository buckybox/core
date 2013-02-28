class Bucky::Kolle::Import
  FILE = File.new(File.join(Rails.root, "lib/bucky/kolle/KlantenMetPakketten2.csv"))

  def self.import
    k = Bucky::Kolle::Import.new(FILE)
    k.import
  end

  attr_accessor :file_name, :customers

  def initialize(file_name)
    self.file_name = file_name
    self.customers = []
  end

  def import
    i = 0
    CSV.parse(@file_name, headers: false) do |row|
      i += 1
      next if i < 5
      
      process_row(row, i - 5)
    end
  end

  Struct.new(:number, :first_name, :last_name, :email, :phone_1
  def process_row(row, i)

  end
end
