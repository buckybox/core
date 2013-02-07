class Account < ActiveRecord::Base
  belongs_to :customer

  has_one :distributor, through: :customer

  has_many :orders,        dependent: :destroy
  has_many :payments,      dependent: :destroy
  has_many :deductions,    dependent: :destroy
  has_many :active_orders, class_name: 'Order', conditions: { active: true }
  has_many :transactions,  autosave: true
  has_many :deliveries,    through: :orders
  has_many :invoices

  has_one :route,    through: :customer
  has_one :address,  through: :customer

  monetize :balance_cents

  attr_accessible :customer, :tag_list

  validates_presence_of :customer_id, :balance

  before_validation :default_balance_and_currency
  after_save :check_customer_threshold

  # A way to double check that the transactions and the balance have not gone out of sync.
  # THIS SHOULD NEVER HAPPEN! If it does fix the root cause don't make this write a new balance.
  # Likely somewhere a transaction is being created manually.
  def calculate_balance(offset_size = 0)
    (transactions.offset(offset_size).sum(&:amount_cents) / 100.0).to_money
  end

  def balance_cents=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def name
    customer.name
  end

  def balance=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def change_balance_to(amount, options = {})
    amount = amount.to_money(currency)
    amount_difference = amount - balance

    transactionable = (options[:transactionable] ? options[:transactionable] : self)
    description = (options[:description] ? options[:description] : 'Manual Transaction.')

    write_attribute(:balance_cents, amount.cents)
    clear_aggregation_cache # without this the composed_of balance attribute does not update

    transaction_options = { amount: amount_difference, transactionable: transactionable, description: description }
    transaction_options.merge!(display_time: options[:display_time]) if options[:display_time]
    transactions.build(transaction_options)
  end

  def add_to_balance(amount, options = {})
    amount = balance + amount.to_money
    change_balance_to(amount, options)
  end

  def subtract_from_balance(amount, options = {})
    add_to_balance((amount * -1), options)
  end

  #all accounts that need invoicing
  def self.need_invoicing
    accounts = []
    Account.all.each { |account| accounts << account if account.needs_invoicing? }
    return accounts
  end

  #future occurrences for all orders on account
  def all_occurrences(end_date)
    occurrences = []

    orders.each do |order|
      order.future_deliveries(end_date).each do |occurrence|
        occurrences << occurrence
      end
    end

    return occurrences.sort { |a,b| a[:date] <=> b[:date] }
  end

  # This holds the core logic for when an invoice should be raised
  def next_invoice_date
    total = balance
    invoice_date = nil
    occurrences = all_occurrences(4.weeks.from_now)

    if total < distributor.invoice_threshold
      # No matter what if the account is below the threshold send out an invoice
      return Date.current
    else
      occurrences.each do |occurrence|
        total -= amount_with_bucky_fee(occurrence[:price])

        if total < distributor.invoice_threshold
          invoice_date = occurrence[:date] - 12.days
          break
        end
      end
    end

    if invoice_date
      invoice_date = Date.current if invoice_date < Date.current

      # After talking to @joshuavial the + 2.days is because of the buisness requirement:
      # it never send an invoice before 2 days after the first delivery
      if deliveries.size > 0 && deliveries.ordered.first.date.present? && deliveries.ordered.first.date >= invoice_date
        invoice_date = deliveries.ordered.first.date + 2.days
      elsif deliveries.size == 0 && occurrences.first && occurrences.first[:date] >= invoice_date
        invoice_date = occurrences.first[:date] + 2.days
      end

      invoice_date = Date.current if invoice_date < Date.current
    end

    return invoice_date
  end

  # Used internally for calculating invoice totals
  # if distributor charges bucky fee in addition to box price return price + bucky fee
  def self.amount_with_bucky_fee(amount, distributor)
    bucky_fee_multiple = distributor.separate_bucky_fee ? (1 + distributor.bucky_box_percentage) : 1
    return amount * bucky_fee_multiple
  end

  def amount_with_bucky_fee(amount)
    Account.amount_with_bucky_fee(amount, distributor)
  end

  def needs_invoicing?
    next_invoice_date.present? && next_invoice_date <= Date.current && invoices.outstanding.count == 0
  end

  def create_invoice
    Invoice.create_for_account(self) if needs_invoicing?
  end

  def check_customer_threshold
    if balance_cents_changed?
      customer.update_halted_status!(nil, Customer::EmailRule.all)
    end
  end

  private

  def default_balance_and_currency
    write_attribute(:balance_cents, 0) if balance_cents.blank?
    write_attribute(:currency, Money.default_currency.to_s) if currency.blank?
  end
end
