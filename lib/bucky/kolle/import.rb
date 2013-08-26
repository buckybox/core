class Bucky::Kolle::Import
  FILE = File.new(File.join(Rails.root, "lib/bucky/kolle/KlantenMetPakketten2.csv"))

  def self.import
    d = Distributor.find(32)
    k = Bucky::Kolle::Import.new(FILE)
    k.import
    setup_delivery_services(d)
    d.import_customers(k.customers)
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
    if seen_customers.key?(c.name)
      c = seen_customers[c.name]
    else
      seen_customers.merge!(c.name => c)
      customers << c
    end
    create_order_for_customer(row, c, i) if row[24].blank? || (Date.parse(row[24]) > Date.current)
    c
  end

  def create_customer(row, i)
    c = Bucky::Import::Customer.new
    i += 1 # Number must be greater than 0
    r = RowReader.new(row, i)

    @distributor ||= Distributor.find(32) # Kollebloem
    c.distributor = @distributor
    c.number = i

    c.first_name = r.first_name
    c.last_name = r.last_name
    c.email = r.email
    c.phone_1 = r.phone_1
    c.phone_2 = r.phone_2
    c.notes = r.notes
    c.discount = 0
    c.account_balance = 0
    c.delivery_address_line_1 = r.delivery_address_line_1
    c.delivery_suburb = r.delivery_suburb
    c.delivery_city = r.delivery_city
    c.delivery_service = r.delivery_service
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
    box.delivery_days = r.delivery_days
    box.next_delivery_date = r.next_delivery_date
    box
  end

  class RowReader
    attr_accessor :row, :index, :t_notes

    def initialize(row, index)
      raise "Row can't be blank" if row.blank?
      self.row = row
      self.index = index
      self.t_notes = ""
    end
    
    def method_missing(*args)
      get_column(args[0])
    end

    def get_column(name)
      case name
      when :first_name
        read_column_unless_blank(name, '-')
      when :email
        read_column_unless_blank(name,"bucky+#{index}@kollebloem.be").gsub(/,/,'.')
      when :delivery_service
        read_column_unless_blank(name, 'geen afhaalpunt')
      when :delivery_address_line_1
        read_column_unless_blank(name, 'geen afhaalpunt')
      when :notes
        get_notes
      when :delivery_frequency
        read_column(:delivery_frequency) == 'TRUE' ? 'fortnightly' : 'weekly'
      when :delivery_days
        row[0] == 'Herbatheek Stef Mintiens' ? 'wednesday' : 'tuesday'
      when :next_delivery_date
        day = row[0] == 'Herbatheek Stef Mintiens' ? 'wednesday' : 'tuesday'
        odd = read_column(:odd) == 'oneven' #oneven === odd
        date = date_of_next(day)
        date = date + 7.days unless date.cweek.odd? == odd
        date
      else
        read_column(name)
      end
    end

    def read_column(name)
      return translate_delivery_service(row[0]) if name == :delivery_service

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
      delivery_service: 0,
      box_type: 14,
      delivery_frequency: 15,
      odd: 16,
      start_trial: 22,
      start_subscription: 23,
      stop_subscription: 24,
      payment_method: 17,
      amount_paid: 18,
      auto_payment: 19,
      auto_payment_number: 20
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

    def translate_delivery_service(delivery_service_name)
      return nil if delivery_service_name.blank?
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
      }.inject({}){|result, element| result.merge(element[0].downcase => element[1])}[delivery_service_name.downcase]
    end

    def get_notes
      add_to_notes(read_column(:notes))
      add_to_notes(row[3], "Straat+nr")
      add_to_notes(row[4], "Postcode")
      add_to_notes(row[5], "Gemeente")
      add_to_notes(row[6], "BTW-nr")
      add_to_notes(row[7], "Rekeningnr")
      add_to_notes(row[8], "Naam rekeninghouder")
      add_to_notes(read_column(:mobile), "Mobile")
      add_to_notes(read_column(:fax), "Fax")
      add_to_notes(read_column(:payment_method), "Betaalwijze")
      add_to_notes(read_column(:amount_paid), "Bedrag")
      add_to_notes(read_column(:auto_payment), "Domiciliering")
      add_to_notes(read_column(:auto_payment_number), "Domnr")
      self.t_notes
    end

    def add_to_notes(s, title=nil)
      unless s.blank?
        if title.blank?
          self.t_notes << s
        else
          self.t_notes << "#{title}: #{s}"
        end
        self.t_notes << "\n"
      end
    end



    def date_of_next(day)
      date  = Date.parse(day)
      delta = date > Date.today ? 0 : 7
      date + delta
    end
  end

  def self.setup_delivery_services(d)
    d.delivery_services.destroy_all
   [["Zottegem", "wereldwinkel
onderweg
Duysburg - van der Linden
Volle Maan
Naturelle
Ruth Brijs
Guido en Elga
Jo en Annelies Verhaevert", :tue],
  ["Aalst","Aalst
Asselman
De Zonnebloem
Iddergem
Linda - Joost
De Boom", :tue],
  ["Geraardsbergen","Apotheker Vogels
Vollezele", :tue],
  ["Kollebloem", "Doornstraat", :tue],
  ["Meerbeke", "Meerbeke", :tue],
  ["Gent", "Herbatheek Stef Mintiens", :wed],
  ["geen afhaalpunt", "geen afhaalpunt", :tue]].each do |name, desc, day|
    d.delivery_services << DeliveryService.create!(name: name, distributor: d, area_of_service: desc, estimated_delivery_time: '16u00', schedule_rule: ScheduleRule.weekly(nil, [day]))
  end
    
  end
end
