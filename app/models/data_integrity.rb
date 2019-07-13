class DataIntegrity
  def self.check_and_print
    Rails.logger.warn check.errors.join("\n")
  end

  def self.check_and_email
    CronLog.log("Running data integrity tests.")

    errors = check.errors
    email(errors) unless errors.empty?
  end

  def self.email(errors)
    options = {
      to: Figaro.env.sysalerts_email,
      subject: "Data integrity tests failed [#{Rails.env}]",
      body: <<-BODY
        Doh! Something does not look right (#{errors.count} errors):

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

  def import_transaction_lists_processing_is_stuck
    ImportTransactionList.draft.where("updated_at < ?", 1.week.ago).find_each do |import_transaction_list|
      error "ImportTransactionList ##{import_transaction_list.id} has a status #{import_transaction_list.status} and was last updated at #{import_transaction_list.updated_at}"
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

  def orders_are_valid
    Order.find_each do |order|
      if order.invalid? && order.errors.keys != [:schedule_rule] # ignore schedule rule inclusion in delivery service for now
        error "Order ##{order.id} is invalid: #{order.errors.full_messages.to_sentence}"
      end
    end
  end

  def past_deliveries_are_not_pending
    Distributor.find_each do |distributor|
      distributor.use_local_time_zone do
        current_time = Time.current
        local_date = current_time.to_date
        local_date -= 1.day if current_time.hour < Distributor::AUTOMATIC_DELIVERY_HOUR

        delivery_lists = distributor.delivery_lists.find_by_date(local_date)
        pending = delivery_lists.deliveries.where(status: "pending") if delivery_lists

        if pending.present?
          error "Distributor ##{distributor.id} (#{current_time} @ #{distributor.time_zone}): #{pending.count} deliveries are still pending for #{local_date}"
        end
      end
    end
  end

  def deduction_count_matches_delivery_count
    Distributor.find_each do |distributor|
      distributor.use_local_time_zone do
        local_time = Time.current
        local_time -= 1.day if local_time.hour < Distributor::AUTOMATIC_DELIVERY_HOUR

        local_date = local_time.to_date
        utc_date = local_time.beginning_of_day.utc.to_date

        delivery_lists = distributor.delivery_lists.find_by_date(local_date)
        delivery_count = delivery_lists ? delivery_lists.deliveries.count : 0

        deduction_count = distributor.transactions
                                     .where(transactionable_type: "Deduction")
                                     .where(reverse_transactionable_id: nil)
                                     .where("display_time::date = ?", utc_date) # display_time is UTC
                                     .count

        if (delivery_count - deduction_count).abs > 5
          error "Distributor ##{distributor.id}: #{delivery_count} deliveries on #{local_date} but #{deduction_count} deductions"
        end
      end
    end
  end

  def accounts_are_valid
    Account.find_each do |account|
      if account.invalid?
        error "Account ##{account.id} is invalid: #{account.errors.full_messages.to_sentence}"
      end
    end
  end

  def orders_have_valid_accounts
    all_ids = Order.pluck('id')
    ids_with_valid_accounts = Order.joins(:account).reorder('').pluck('orders.id')
    diff = all_ids - ids_with_valid_accounts

    diff.each do |id|
      error "Order ##{id} has invalid account"
    end
  end

  def order_extras_have_valid_foreign_keys
    all_ids = OrderExtra.pluck('id')
    ids_with_valid_foreign_keys = OrderExtra.joins(:extra).joins(:order).pluck('order_extras.id')
    diff = all_ids - ids_with_valid_foreign_keys

    diff.each do |id|
      error "OrderExtra ##{id} has invalid foreign keys"
    end
  end

  def orders_have_generated_valid_packages_and_deliveries
    Distributor.find_each do |distributor|
      (distributor.window_start_from..(distributor.window_end_at - 1)).each do |date|
        distributor.packing_list_by_date(date).packages.group_by(&:order_id).each do |order_id, packages|
          if packages.count != 1
            error "Distributor ##{distributor.id}: PackingList for #{date} has Order ##{order_id} with #{packages.count} packages"
          end
        end

        distributor.delivery_list_by_date(date).deliveries.group_by(&:order_id).each do |order_id, deliveries|
          if deliveries.count != 1
            error "Distributor ##{distributor.id}: DeliveryList for #{date} has Order ##{order_id} with #{deliveries.count} deliveries"
          end
        end
      end
    end
  end

  # NOTE: not used but useful for debugging purposes
  def customer_numbers_have_no_gaps
    Distributor.find_each do |distributor|
      max_number = distributor.customers.maximum(:number) || 0
      missing_numbers = 1.upto(max_number).to_a - distributor.customers.map(&:number)

      if missing_numbers.present?
        error "Distributor ##{distributor.id}: #{missing_numbers.size} customer numbers are missing out: #{missing_numbers.join(', ')} (max assigned number = #{max_number})"
      end
    end
  end

private

  def self.check
    checker = DataIntegrity.new

    checker.account_balance_equals_sum_of_transactions
    checker.account_currency_matches_distributor_currency
    checker.import_transaction_lists_processing_is_stuck
    checker.distributor_currency_is_valid
    checker.orders_are_valid
    checker.past_deliveries_are_not_pending
    checker.deduction_count_matches_delivery_count
    checker.accounts_are_valid
    checker.orders_have_valid_accounts
    # checker.order_extras_have_valid_foreign_keys # FIXME: some orders get deleted but not their extras somehow
    checker.orders_have_generated_valid_packages_and_deliveries

    checker
  end

  def error(message)
    @errors << message
  end
end
