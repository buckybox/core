class Invoice < ActiveRecord::Base
  belongs_to :account

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  composed_of :balance,
    :class_name => "Money",
    :mapping => [%w(balance_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  serialize :transactions
  serialize :deliveries

  scope :outstanding, where(:paid => false)

  before_create :generate_number
  after_initialize :set_defaults

  validates_presence_of :account_id
  validates_uniqueness_of :number, :allow_nil => false

  def set_defaults
    self.start_date ||= 4.weeks.ago.to_date
    self.end_date ||= 4.weeks.from_now.to_date
    calculate_amount if amount.nil?
  end

  def calculate_amount
    return unless account
    self.balance = account.balance
    self.transactions = account.transactions.order(:created_at).where(["created_at >= ? AND created_at <= ?", start_date, Date.current]).collect {|t| {:date => t.created_at.to_date, :amount => t.amount, :description => t.description}}
    self.deliveries = account.deliveries.pending.where("date >= ? AND date <= ?", Date.current, end_date).collect {|d| {:date => d.date, :description => d.order.box.name, :amount => d.order.price}}
    self.amount = balance - deliveries.inject(Money.new(0)) {|sum, delivery| sum += delivery[:amount]}
    return amount
  end

  private
  def generate_number
    last_invoice = account.invoices.order('number DESC').limit(1).first
    self.number = last_invoice.nil? ? 1 : last_invoice.number + 1
  end

end
