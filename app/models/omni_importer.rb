class OmniImporter < ActiveRecord::Base
  attr_accessible :global, :country_id, :import_transaction_list, :name, :rules, :remove_import_transaction_list, :import_transaction_list_cache, :tag_list

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
    [[name], [[country.try(:name), country.try(:full_name)].uniq, tags].flatten.compact.join(", ")].join(' - ')
  end

  def import(csv_path)
    return @omni_import unless @omni_import.blank?

    rows = CSV.read(csv_path)
    @omni_import = Bucky::TransactionImports::OmniImport.new(rows, YAML.load(rules))

    return self
  end

  def rows
    @rows ||= @omni_import.bucky_rows
  end

  def rows_are_valid?
    rows.all?(&:valid?)
  end

  def expected_format
    "expected_format"
  end

  def bank_name
    name
  end

  def format_type
    ['bank_deposit', 'credit_card', 'paypal'].each do |format|
      return format.titleize if tags.any?{|t| t.name == format}
    end

    ''
  end

  def header?
    Bucky::TransactionImports::OmniImport.new([], YAML.load(rules)).header?
  end
end
