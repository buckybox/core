class Invoice < ActiveRecord::Base
  belongs_to :account

  has_one :distributor, through: :account
  has_one :customer,    through: :account

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  composed_of :balance,
    class_name: "Money",
    mapping: [%w(balance_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  serialize :transactions
  serialize :deliveries

  scope :outstanding, where(paid: false)

  after_initialize :set_defaults
  before_create :generate_number

  validates_presence_of :account_id
  validates_uniqueness_of :number, allow_nil: false, scope: :account_id
  validates_numericality_of :amount_cents, greater_than: 0

  def set_defaults
    self.start_date ||= 4.weeks.ago.to_date
    self.end_date ||= 4.weeks.from_now.to_date
    self.date = Date.current
  end

  def full_number
    "#{account.customer.number}-#{number}"
  end

  def starting_balance
    balance - transactions.inject(Money.new(0)) { |sum, t| sum += t[:amount] }
  end

  #creates invoices for all accounts which need it
  #TODO we are not doing invoicing at the moment
  def self.generate_invoices
    #invoices = []

    #Account.all.each do |a|
      #if invoice = a.create_invoice
        #invoices << invoice
        #CustomerMailer.invoice(invoice).deliver
        #CronLog.log("Delivered invoice for account #{a.id}")
      #end
    #end

    #return invoices
  end

  def calculate_amount
    return unless account
    self.balance = account.balance

    account_transactions = account.transactions.unscoped.order(:created_at).where(["created_at >= ? AND created_at <= ?", start_date, Date.current])
    self.transactions = account_transactions.map { |t| { date: t.created_at.to_date, amount: t.amount, description: t.description } }

    #TODO - check with will how he wants to handle the distributor bucky fee
    # currently if the fee is separate I just add it onto the price through account.amount_with_bucky_fee but it might be he wants it as a separate line item on the invoice, or displayed as a total at the bottom or something.

    #check for deliveries on today that are pending
    account_deliveries = account.deliveries.unscoped.pending.includes(:delivery_list).order("\"deliveries\".created_at").where(["\"delivery_lists\".date >= ? AND \"delivery_lists\".date <= ?", Date.current, end_date])
    real_deliveries = account_deliveries.map { |d| { date: d.date, amount: account.amount_with_bucky_fee(d.package.price), description: d.description } }

    #save all_occurrences
    account_occurrences = account.all_occurrences(end_date.to_time_in_current_zone)
    occurrences = account_occurrences.map { |o| { date: o[:date], description: o[:description], amount: account.amount_with_bucky_fee(o[:price]) } }

    self.deliveries = real_deliveries + occurrences
    self.amount = deliveries.inject(Money.new(0)) { |sum, occurrence| sum += occurrence[:amount] } - balance

     return (amount > 0) ? amount : 0
  end

  def self.create_for_account(account)
    invoice = Invoice.for_account(account)
    invoice.save! if invoice.amount > 0

    return invoice
  end

  def self.for_account(account)
    invoice = Invoice.new(account: account)
    invoice.calculate_amount

    return invoice
  end

  private

  def generate_number
    return if number.present? || !account.present?

    last_invoice = account.invoices.order('number DESC').limit(1).first
    self.number = last_invoice.nil? || last_invoice.number.nil? ? 1 : last_invoice.number + 1
  end
end
