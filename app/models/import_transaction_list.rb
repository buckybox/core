class ImportTransactionList < ActiveRecord::Base

  belongs_to :distributor
  has_many :import_transactions, autosave: true, validate: true, dependent: :destroy

  accepts_nested_attributes_for :import_transactions
  
  mount_uploader :csv_file, ImportTransactionListUploader

  FILE_FORMATS = [["Kiwibank", "kiwibank"], ["St George Australia", "st_george_au"], ["BNZ", "bnz"]]
  ACCOUNTS = [:kiwibank, :paypal, :st_george_au, :bnz]
  SOURCES = [:manual, :kiwibank_csv]

  validate :csv_ready, on: :create
  validates :file_format, inclusion: {in: FILE_FORMATS.collect(&:last)}
  validates :csv_file, presence: true

  before_create :import_rows

  default_value_for :draft, true

  scope :ordered, order("created_at DESC")

  attr_accessible :csv_file, :file_format, :import_transactions_attributes, :draft

  def account
    ACCOUNTS[account_type]
  end

  def source
    SOURCES[source_type]
  end

  def import_rows
    csv_parser.rows.each do |row|
      import_transactions << ImportTransaction.new_from_row(row, self, distributor)
    end
    import_transactions
  end

  def file_format
    read_attribute(:file_format) || FILE_FORMATS.first.last
  end
  
  def parser_class
    "Bucky::TransactionImports::#{file_format.camelize}".constantize
  end
  
  def csv_parser
    if @parser.blank?
      @parser = parser_class.new
      @parser.import(csv_file.current_path) if errors.blank? && csv_file.present?
    end
    @parser
  end

  def process_import_transactions_attributes(import_transaction_list_attributes)
    # Expecting transactions_attributes to look like [1, {"id": 234, "customer_id":12 },
    #                                                 2, {"id": 65, "customer_id":1}....]
    transactions_attributes = import_transaction_list_attributes[:import_transactions_attributes]                                                 

    hash_transactions_attributes = transactions_attributes.clone.inject({}) do |hash, element|
      element = element.last
      hash.merge(element["id"] => element)
    end

    # Pull out the non customer_ids (duplicate, not_a_customer, etc..)
    transactions_attributes.each do |id, transaction_attributes|
      if ImportTransaction::MATCH_TYPES.include?(transaction_attributes['customer_id'])
        transaction_attributes['match'] = transaction_attributes['customer_id']
        transaction_attributes['customer_id'] = nil
      else
        transaction_attributes['match'] = ImportTransaction::MATCH_MATCHED
      end
    end

    #Remove any customers which shouldn't be here
    hash_customer_ids = distributor.customer_ids.inject({}){|hash, element| hash.merge(element.to_s => true)}
    transactions_attributes = transactions_attributes.select do |id, transaction_attributes|
      hash_customer_ids.key?(transaction_attributes[:customer_id])
    end
    import_transaction_list_attributes
  end

  def process_attributes(attr)
    self.draft = false
    update_attributes(attr.merge(draft: false))
  end

  def processed?
    !draft?
  end

  def csv_valid?
    errors.blank? && csv_parser.present? && csv_parser.valid?
  end

  private

  def csv_ready
    errors.add(:csv_file, "Seems to be a problem with the csv file.") unless csv_valid?
  end
end
