class ImportTransactionList < ActiveRecord::Base

  belongs_to :distributor
  has_many :import_transactions, autosave: true, validate: true, dependent: :destroy
  belongs_to :omni_importer

  accepts_nested_attributes_for :import_transactions

  mount_uploader :csv_file, ImportTransactionListUploader

  validates_presence_of :csv_file

  validate :csv_ready, on: :create

  before_create :import_rows

  default_value_for :draft, true

  scope :ordered, order("created_at DESC")
  scope :draft, where(['import_transaction_lists.draft = ?', true])
  scope :processed, where(['import_transaction_lists.draft = ?', false])

  attr_accessible :csv_file, :import_transactions_attributes, :draft, :omni_importer_id
  delegate :payment_type, to: :omni_importer, allow_nil: true

  # Used to move the csv_files to the new directory private_uploads
  def move_old_csv_file
    original_path = [nil, "omni_importer", "bnz", "kiwibank", "anz", "national", "paypal", "reo_uk", "st_george_au", "uk_coop_bank", "uk_lloyds_tsb"].collect{|f|
      ["#{Rails.root}/public/system/uploads/payments/csv", f, "#{read_attribute(:csv_file)}"].compact.join('/')
    }.find{|path| File.exists?(path)}
    unless original_path.blank?
      FileUtils.mkdir_p(File.dirname(csv_file.to_s))
      File.rename(original_path, csv_file.to_s)
    end
  end

  def account
    omni_importer.name if omni_importer.present?
  end

  def has_failed?
    errors.size > 0 || (csv_parser.present? && !csv_parser.rows.reject(&:valid?).size.zero?)
  end

  def error_messages
    if errors.size > 0
      errors.full_messages.join(', ')
    elsif csv_parser.present?
      csv_parser.rows.find(&:invalid?).errors.full_messages.join(', ')
    end
  end

  def has_payment_type?
    payment_type.present?
  end

  def import_rows
    csv_parser.rows.each do |row|
      import_transactions << ImportTransaction.new_from_row(row, self, distributor)
    end

    return import_transactions
  end

  def csv_parser
    return @parser unless @parser.blank?
    return nil unless errors.blank? && csv_file.present?

    @parser = omni_importer.import(csv_file.current_path)

    return @parser
  end

  def file_format
    "omni_importer"
  end

  def process_import_transactions_attributes(import_transaction_list_attributes)
    # Expecting transactions_attributes to look like [1, {"id": 234, "customer_id":12 },
    #                                                 2, {"id": 65, "customer_id":1}....]
    transactions_attributes = import_transaction_list_attributes[:import_transactions_attributes]

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
    begin
      csv_parser.present? && csv_parser.respond_to?(:rows_are_valid?) && csv_parser.rows_are_valid?
    rescue StandardError => ex # Catch a totally crappy file
      logger.warn(ex.to_s)
      return false
    end
    if csv_parser.is_a?(OmniImporter)
      errors.blank? && csv_parser.present? && csv_parser.rows_are_valid?
    else
      errors.blank? && csv_parser.present? && csv_parser.valid?
    end
  end

  def can_process?
    with_lock do
      return false if processed? || processing?
      set_processing!
    end
    true
  end

  def processing_failed!
    set_pending!
  end

  state_machine :status, initial: :pending do
    event :set_processing! do
      transition all - :processing => :processing
    end

    event :set_pending! do
      transition all => :pending
    end
  end
  private

  def csv_ready
    errors.add(:csv_file, "Seems to be a problem with the csv file.") unless csv_valid?
  end
end
