class Bucky::Kolle::Import
  FILE = File.new(File.join(Rails.root, "lib/bucky/kolle/KlantenMetPakketten2.csv"))

  def self.import
    k = Bucky::Kolle::Import.new(FILE)
    k.import
    k
  end

  def self.test(i=0)
    k = Bucky::Kolle::Import.new(FILE)
    k.process_row(k.get_row(i), i)
  end

  def get_row(j)
    result = nil
    i = 0
    j = j + 5
    CSV.foreach(@file_name, headers: false) do |row|
      i += 1
      next if i < 5
      if i == j
        result = row
        break
      end
    end
    result
  end

  attr_accessor :file_name, :customers, :seen_customers

  def initialize(file_name)
    self.file_name = file_name
    self.customers = []
    self.seen_customers = {}
  end

  def import
    i = 0
    CSV.foreach(@file_name, headers: false) do |row|
      i += 1
      next if i < 5
      
      process_row(row, i - 5)
    end
  end

  def process_row(row, i)
    c = create_customer(row, i)
    if seen_customers.key?(c.unique_string)
      c = seen_customers[c.unique_string]
    else
      seen_customers.merge!(c.unique_string => true)
      customers << c
    end
    create_order_for_customer(row, c, i)
    c
  end

  def create_customer(row, i)
    c = Bucky::Import::Customer.new

    r = RowReader.new(row, i)

    @distributor ||= Distributor.find(32) # Kollebloem
    c.distributor = @distributor
    c.number = i

    c.first_name = r.first_name
    c.last_name = r.last_name
    c.email = r.email
    c.phone_1 = r.phone_1
    c.notes = r.notes
    c.discount = 0
    c.account_balance = 0
    c.delivery_address_line_1 = r.delivery_address_line_1
    c.delivery_suburb = r.delivery_suburb
    c.delivery_city = r.delivery_city
    c.delivery_route = r.delivery_route
    c
  end

  def create_order_for_customer(row, c, i)
    box = create_box(row, i)
    c.add_box(box)
  end

  def create_box(row, i)
    box = Bucky::Import::Box.new

    r = RowReader.new(row, i)

    box.box_type = r.box_type
    box.delivery_frequency = r.delivery_frequency
  end

  class RowReader
    attr_accessor :row, :index

    def initialize(row, index)
      raise "Row can't be blank" if row.blank?
      self.row = row
      self.index = index
    end
    
    def method_missing(*args)
      get_column(args[0])
    end

    def get_column(name)
      case name
      when :email
        read_column_unless_blank(name,"bucky+#{index}@kollebloem.be")
      when :delivery_route
        read_column_unless_blank(name, 'geen afhaalpunt')
      when :notes
        notes = ""
        notes << read_column(:notes)
        notes << "Mobile: #{read_column(:mobile)}" unless read_column(:mobile).blank?
        notes << "Fax: #{read_column(:fax)}" unless read_column(:fax).blank?
        notes
      when :delivery_frequency
        read_column(:delivery_frequency) == 'TRUE' ? 'fortnightly' : 'weekly'
      when :delivery_days
        row[0] == 'Herbatheek Stef Mintiens' ? 'wednesday' : 'tuesday'
      else
        read_column(name)
      end
    end

    def read_column(name)
      return translate_route(row[0]) if name == :delivery_route

      row[{
      first_name: 2,
      last_name: 1,
      email: 13,
      phone_1: 9,
      phone_2: 10,
      mobile: 11,
      fax: 12,
      notes: 21,
      delivery_address_line_1: 0,
      delivery_suburb: 0,
      delivery_city: 0,
      delivery_route: 0,
      box_type: 14,
      delivery_frequency: 14
      }[name]]
    rescue Exception => e
      puts name
      raise e
    end

    def read_column_unless_blank(name, sub)
      result = read_column(name)
      if result.blank?
        sub
      else
        result
      end
    end

    def translate_route(route_name)
      return nil if route_name.blank?
      {
        "wereldwinkel" => "Zottegem",
        "onderweg" => "Zottegem",
        "Duysburg - van der Linden" => "Zottegem",
        "Volle Maan" => "Zottegem",
        "Naturelle" => "Zottegem",
        "Ruth Brijs" => "Zottegem",
        "Guido en Elga" => "Zottegem",
        "Jo en Annelies Verhaevert" => "Zottegem",
        "Aalst" => "Aalst",
        "Asselman" => "Aalst",
        "De Zonnebloem" => "Aalst",
        "Iddergem" => "Aalst",
        "Linda - Joost" => "Aalst",
        "De Boom" => "Aalst",
        "Apotheker Vogels" => "Geraardsbergen",
        "Vollezele" => "Geraardsbergen",
        "Doornstraat" => "Kollebloem",
        "Meerbeke" => "Meerbeke", 
        "Herbatheek Stef Mintiens" => "Gent"
      }.inject({}){|result, element| result.merge(element[0].downcase => element[1])}[route_name.downcase]
    end
  end
end
