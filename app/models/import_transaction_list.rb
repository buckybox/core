class ImportTransactionList < ActiveRecord::Base

  belongs_to :distributor
  has_many :import_transactions, autosave: true, validate: true, dependent: :destroy

  accepts_nested_attributes_for :import_transactions

  mount_uploader :csv_file, ImportTransactionListUploader

  FILE_FORMATS = [["Kiwibank", "kiwibank"], ["St George Australia", "st_george_au"], ["Paypal", "paypal"], ["BNZ", "bnz"], ["National Bank", "national"], ["ANZ", "anz"]]
  ACCOUNTS = [:kiwibank, :paypal, :st_george_au, :bnz, :national]

  validates_presence_of :csv_file
  validates_inclusion_of :file_format, in: FILE_FORMATS.map(&:last)
  validate :csv_ready, on: :create

  before_create :import_rows

  default_value_for :draft, true

  scope :ordered, order("created_at DESC")
  scope :draft, where(['import_transaction_lists.draft = ?', true])
  scope :processed, where(['import_transaction_lists.draft = ?', false])

  attr_accessible :csv_file, :file_format, :import_transactions_attributes, :draft

  def account
    ImportTransactionList.label_for_file_format(file_format)
  end

  def self.label_for_file_format(file_format)
    FILE_FORMATS.find{ |name, code| code == file_format }.first
  end

  def import_rows
    csv_parser.rows.each do |row|
      import_transactions << ImportTransaction.new_from_row(row, self, distributor)
    end

    return import_transactions
  end

  def file_format
    in_db = read_attribute(:file_format)

    if in_db.present?
      in_db
    else
      distributor.present? ? distributor.last_csv_format : FILE_FORMATS.first.last
    end
  end

  def parser_class
    "Bucky::TransactionImports::#{file_format.camelize}".constantize
  end

  def csv_parser
    if @parser.blank? && file_format.present?
      @parser = parser_class.new
      @parser.import(csv_file.current_path) if errors.blank? && csv_file.present?
    end

    return @parser
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
      ImportTransaction.process_attributes(transaction_attributes)
    end

    # Remove any customers which shouldn't be here
    hash_customer_ids = distributor.customer_ids.inject({}) { |hash, element| hash.merge(element.to_s => true) }
    transactions_attributes = transactions_attributes.select do |id, transaction_attributes|
      hash_customer_ids.key?(transaction_attributes[:customer_id])
    end

    return import_transaction_list_attributes
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
