class DataIntegrity
  def self.check
    checker = DataIntegrity.new
    checker.account_balance_equals_sum_of_transactions
    checker.import_transaction_lists_processing_is_stuck
    checker
  end

  def self.check_and_email
    errors = check.errors
    email(errors) unless errors.empty?
  end

  def self.email errors
    options = {
      to: Figaro.env.sysalerts_email,
      subject: "Data integrity tests failed [#{Rails.env}]",
      body: <<-BODY
        Doh! Something does not look right:

        #{errors.join("\n")}

        Tip: you can run these tests manually with `VERBOSE=1 rails r 'DataIntegrity.check'`
      BODY
    }

    AdminMailer.information_email(options).deliver
  end

  attr_reader :errors

  def initialize
    @errors = []
    @verbose = ENV['VERBOSE']
  end

  def account_balance_equals_sum_of_transactions
    Account.find_each do |account|
      sum = account.transactions.sum(:amount_cents)
      balance = account.balance_cents

      if sum != balance
        error "Account ##{account.id}: transactions sum = #{sum} != #{balance} = balance"
      end
    end
  end

  def import_transaction_lists_processing_is_stuck
    ImportTransactionList.where(
      "status != 'pending' AND status != 'processed' AND updated_at < ?", 24.hours.ago
    ).each do |import_transaction_list|
      error "ImportTransactionList ##{import_transaction_list.id} has a status #{import_transaction_list.status} and was last updated at #{import_transaction_list.updated_at}"
    end
  end

private

  def error message
    @errors << message
    puts message if @verbose
  end
end

