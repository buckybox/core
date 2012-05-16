class ImportTransactionList < ActiveRecord::Base

  belongs_to :distributor
  has_many :import_transactions, autosave: true, validate: true, dependent: :destroy

  accepts_nested_attributes_for :import_transactions
  
  mount_uploader :csv_file, ImportTransactionListUploader

  ACCOUNTS = [:kiwibank, :paypal]
  SOURCES = [:manual, :kiwibank_csv]

  validates_presence_of :csv_file, if: :new_record?
  validate :csv_ready, if: :new_record?

  before_create :import_rows

  default_value_for :confirmed, false

  scope :ordered, order("created_at DESC")

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
  
  def csv_valid?
    csv_parser.valid?
  end
  
  def csv_parser
    if @kiwibank.blank?
      @kiwibank = Bucky::TransactionImports::Kiwibank.new
      @kiwibank.import(self.csv_file.current_path)
    end
    @kiwibank
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

  private

  def mark_processed
    self.draft = false
    save #import_transactions has autosave, which should do the business of saving and validating the above
  end

  def csv_ready
    errors.add(:csv_file, "Seems to be a problem with csv file.") unless csv_valid?
  end
end
