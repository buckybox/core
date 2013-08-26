class OmniImporter < ActiveRecord::Base
  PAYPAL_ID = 16

  attr_accessible :global, :country_id, :import_transaction_list, :name, :rules, :remove_import_transaction_list, :import_transaction_list_cache, :tag_list, :payment_type, :bank_name

  mount_uploader :import_transaction_list, ImportTransactionListUploader

  acts_as_taggable

  belongs_to :country
  has_and_belongs_to_many :distributors

  scope :ordered, joins("LEFT JOIN countries ON countries.id = omni_importers.country_id").order('countries.alpha2, omni_importers.name')

  scope :paypal, -> { where(payment_type: "PayPal") }
  scope :credit_card, -> { where(payment_type: "Credit Card") }
  scope :bank_deposit, -> { where(payment_type: "Bank Deposit") }
  scope :manual_processing, -> { where(payment_type: "Manual Processing") }

  # used to name the uploaded files
  def file_format
    'omni_importer'
  end

  def test_rows
    @rows ||=  Bucky::TransactionImports::OmniImport.csv_read(import_transaction_list.path)
  rescue StandardError => ex
    errors.add(:import_transaction_list, ex.message)
    @rows ||= [[]]
  end

  def select_label
    [[name], [payment_type, [country.try(:name), country.try(:full_name)].uniq, tags].flatten.compact.join(", ")].join(' - ')
  end

  def import(csv_path)
    return @omni_import unless @omni_import.blank?

    rows =  Bucky::TransactionImports::OmniImport.csv_read(csv_path)
    @omni_import = Bucky::TransactionImports::OmniImport.new(rows, YAML.load(rules))

    return self
  end

  def rows
    @rows ||= @omni_import.bucky_rows(name)
  end

  def rows_are_valid?
    rows.all?(&:valid?)
  end

  def expected_format
    ""
  end

  def tag_name
    [name, country.try(:full_name)].compact.join(' - ')
  end

  def format_type
    payment_type
  end

  def header?
    Bucky::TransactionImports::OmniImport.new([], YAML.load(rules)).header?
  end

end
