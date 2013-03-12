class OmniImporter < ActiveRecord::Base
  attr_accessible :global, :country_id, :import_transaction_list, :name, :rules, :remove_import_transaction_list, :import_transaction_list_cache, :tag_list, :payment_type

  mount_uploader :import_transaction_list, ImportTransactionListUploader

  acts_as_taggable

  belongs_to :country
  has_and_belongs_to_many :distributors

  def file_format
    'omni_importer'
  end

  def test_rows
    @rows ||= CSV.parse(import_transaction_list.read)
  rescue StandardError => ex
    errors.add(:import_transaction_list, ex.message)
  end

  def select_label
    [[name], [payment_type, [country.try(:name), country.try(:full_name)].uniq, tags].flatten.compact.join(", ")].join(' - ')
  end

  def import(csv_path)
    return @omni_import unless @omni_import.blank?

    rows = CSV.read(csv_path)
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

  def bank_name
    name
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
