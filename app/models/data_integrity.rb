class DataIntegrity
  def self.check_and_print
    puts check.errors.join("\n")
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

        Tip: you can run these tests manually with `RAILS_ENV=#{Rails.env} bundle exec rails r 'DataIntegrity.check_and_print'`
      BODY
    }

    AdminMailer.information_email(options).deliver
  end

  attr_reader :errors

  def initialize
    @errors = []
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

  def account_currency_matches_distributor_currency
    Account.find_each do |account|
      distributor_currency = account.distributor.currency

      if account.currency != distributor_currency
        error "Account ##{account.id}: currency = #{account.currency.inspect} != #{distributor_currency.inspect} = distributor's currency"
      end
    end
  end

  def distributor_currency_is_valid
    Distributor.find_each do |distributor|
      if distributor.currency !~ /[A-Z]{3}/
        error "Distributor ##{distributor.id}: currency = #{distributor.currency.inspect} !~ /[A-Z]{3}/"
      end
    end
  end

private

  def self.check
    checker = DataIntegrity.new

    checker.account_balance_equals_sum_of_transactions
    checker.account_currency_matches_distributor_currency
    checker.distributor_currency_is_valid

    checker
  end

  def error message
    @errors << message
  end
end

