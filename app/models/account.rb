class Account < ActiveRecord::Base
  belongs_to :customer

  has_one :distributor, :through => :customer

  has_many :orders, :dependent => :destroy
  has_many :payments, :dependent => :destroy

  has_many :transactions
  has_many :deliveries, :through => :orders
  has_many :invoices

  composed_of :balance,
    :class_name => "Money",
    :mapping => [%w(balance_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  acts_as_taggable

  attr_accessible :customer, :tag_list

  before_validation :default_balance_and_currency

  validates_presence_of :customer, :balance

  def balance_cents=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def balance=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def change_balance_to(amount, options = {})
    amount = amount.to_money
    amount_difference = amount - balance

    options.merge!(kind: 'amend') unless options[:kind]
    options.merge!(description: "Balance changed from #{balance} to #{amount}.") unless options[:description]

    write_attribute(:balance_cents, amount.cents)
    write_attribute(:currency, amount.currency.to_s || Money.default_currency.to_s)
    clear_aggregation_cache # without this the composed_of balance attribute does not update

    transactions.build(kind: options[:kind], amount: amount_difference, description: options[:description])
  end

  def add_to_balance(amount, options = {})
    amount = balance + amount.to_money
    change_balance_to(amount, options)
  end

  def subtract_from_balance(amount, options = {})
    add_to_balance((amount * -1), options)
  end

  def next_invoice_date
    total = balance
    invoice_date = nil

    if total < distributor.invoice_threshold
      invoice_date =  Date.today
    else
      deliveries.pending.each do |delivery|
        bucky_fee_multiple = distributor.separate_bucky_fee ? (1 + distributor.fee) : 1
        total -= delivery.order.price * bucky_fee_multiple
        if total < distributor.invoice_threshold
          invoice_date = delivery.date.to_date - 12.days
          break
        end
      end
    end

    if invoice_date
      invoice_date = Date.today if invoice_date < Date.today

      if deliveries.first.date >= invoice_date - 2.days
        invoice_date = deliveries.first.date + 2.days
      end
    end


    return invoice_date

  end

  def create_invoice
    if next_invoice_date <= Date.today && invoices.outstanding.count == 0
      Invoice.create(:account => self) 
    end
  end

  protected

  def default_balance_and_currency
    write_attribute(:balance_cents, 0) if balance_cents.blank?
    write_attribute(:currency, Money.default_currency.to_s) if currency.blank?
  end
end
