class Distributor::Map::Pin
  attr_reader :name, :address, :ll, :webstore

  def initialize(args)
    @name     = args[:name]
    @address  = args[:address]
    @ll       = args[:ll]
    @webstore = args[:webstore]
  end
end
