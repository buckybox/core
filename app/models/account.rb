class Account < ActiveRecord::Base
  belongs_to :customer, touch: true

  has_one :distributor, through: :customer

  has_many :orders,          dependent: :destroy
  has_many :payments,        dependent: :destroy
  has_many :deductions,      dependent: :destroy
  has_many :active_orders,   -> { where(active: true) }, class_name: 'Order'
  has_many :transactions,    dependent: :destroy, autosave: true
  has_many :deliveries,      through: :orders

  has_one :delivery_service, through: :customer
  has_one :address,          through: :customer

  monetize :balance_cents

  attr_accessible :customer, :tag_list, :default_payment_method

  before_validation :default_balance_and_currency

  validates_presence_of :customer, :balance, :currency
  validate :validates_default_payment_method

  delegate :name, to: :customer

  # A way to double check that the transactions and the balance have not gone out of sync.
  # THIS SHOULD NEVER HAPPEN! If it does fix the root cause don't make this write a new balance.
  # Likely somewhere a transaction is being created manually.
  # FIXME
  def calculate_balance(offset_size = 0)
    CrazyMoney.new(transactions.offset(offset_size).map(&:amount).sum)
  end

  def balance_cents=(_value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def balance=(_value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def add_to_balance(amount, options = {})
    create_transaction(amount, options)
  end

  def subtract_from_balance(amount, options = {})
    create_transaction(amount * -1, options)
  end

  def create_transaction(amount, options = {})
    raise "amount should not be a float as floats are inaccurate for currency" if amount.is_a? Float

    amount = CrazyMoney.new(amount)
    transactionable = (options[:transactionable] ? options[:transactionable] : self)
    description = (options[:description] ? options[:description] : I18n.t('models.account.manual_transaction'))
    transaction_options = { amount: amount, transactionable: transactionable, description: description }
    transaction_options.merge!(display_time: options[:display_time]) if options[:display_time]
    transaction = nil

    with_lock do
      Account.update_counters(self.id, balance_cents: amount.cents)
      touch # XXX: Account.update_counters doesn't touch `updated_at`
      transaction = transactions.create(transaction_options)
    end

    # force update `balance_cents` attribute changed via `Account.update_counters` above
    self.reload
    update_halted_status

    transaction
  end

  def change_balance_to!(amount, opts = {})
    raise "amount should not be a float as floats are unprecise for currency" if amount.is_a? Float

    amount = CrazyMoney.new(amount)
    with_lock do
      create_transaction(amount - balance, opts)
    end
  end

  # future occurrences for all orders on account
  def all_occurrences(end_date)
    occurrences = []

    orders.each do |order|
      order.future_deliveries(end_date).each do |occurrence|
        occurrences << occurrence
      end
    end

    occurrences.sort { |a, b| a[:date] <=> b[:date] }
  end

  def update_halted_status
    customer.update_halted_status!(nil, Customer::EmailRule.all)
  end

  def balance_at(date)
    BigDecimal.new(transactions.where(['display_time <= ?', date]).sum(&:amount_cents)) / BigDecimal.new(100)
  end

private

  def default_balance_and_currency
    self[:balance_cents] = 0 if balance_cents.blank?
    self[:currency] = customer.currency if currency.blank?
  end

  def validates_default_payment_method
    return if default_payment_method.nil? ||
              default_payment_method == PaymentOption::PAID ||
              default_payment_method.in?(Distributor.all_payment_options.keys.map(&:to_s))

    errors.add(:default_payment_method, "Unknown payment method #{default_payment_method.inspect}")
  end
end
