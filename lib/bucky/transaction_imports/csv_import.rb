module Bucky::TransactionImports
  class CsvImport
    require 'csv'
    
    include ActiveModel::Validations

    attr_accessor :rows

    validate :rows_are_valid

    def import(file)
      import_csv(File.read(file))
    end
    
    def import_csv(csv)
      raise "This method needs to be defined in a child class"
      # and call add_row(date, description, amount, row_index, parser_instance)
    end

    def expected_format
      raise "This method needs to be defined in a child class"
    end
    
    def bank_name
      raise "This method needs to be defined in a child class"
    end
    
    def add_row(date, description, amount, index, parser)
      @rows ||= []
      @rows << Row.new(date, description, amount, index, parser)
    end

    def credit_rows
      @credit_rows ||= rows.select(&:credit?)
    end

    def debit_rows
      @debit_rows ||= rows.select(&:debit?)
    end

    def rows_are_valid
      unless @rows.all?(&:valid?)
        errors.add(:base, "There was a problem with the file you uploaded.")
      end
    end

    #def errors
    #  Struct.new(:full_messages).new(@rows.collect{|r| r.errors.blank? ? nil : r.to_s + " " + r.errors.full_messages.join(', ')}.select(&:present?))
    #end

  end
end
