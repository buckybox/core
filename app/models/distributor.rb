class Distributor < ActiveRecord::Base
  include IceCube

  has_one :bank_information,    :dependent => :destroy
  has_one :invoice_information, :dependent => :destroy

  has_many :boxes,          :dependent => :destroy
  has_many :routes,         :dependent => :destroy
  has_many :orders,         :dependent => :destroy, :through => :boxes
  has_many :deliveries,     :dependent => :destroy, :through => :orders
  has_many :payments,       :dependent => :destroy
  has_many :accounts,       :dependent => :destroy, :through => :customers
  has_many :transactions,   :dependent => :destroy, :through => :accounts
  has_many :customers,      :dependent => :destroy
  has_many :events,         :dependent => :destroy
  has_many :delivery_lists, :dependent => :destroy
  has_many :packing_list,   :dependent => :destroy

  serialize :daily_lists_schedule,   Hash
  serialize :auto_delivery_schedule, Hash

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :company_logo, CompanyLogoUploader

  composed_of :invoice_threshold,
    :class_name => "Money",
    :mapping => [%w(invoice_threshold_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url, :company_logo, :completed_wizard

  validates_presence_of :email
  validates_uniqueness_of :email

  validates_presence_of :name, :on => :update
  validates_uniqueness_of :name, :on => :update

  before_save :parameterize_name
  before_save :downcase_email
  before_save :generate_daily_lists_schedule, :if => 'daily_lists_schedule.to_s.blank?'
  before_save :generate_auto_delivery_schedule, :if => 'auto_delivery_schedule.to_s.blank?'

  def daily_lists_schedule
    Schedule.from_hash(self[:daily_lists_schedule]) if self[:daily_lists_schedule]
  end

  def daily_lists_schedule=(daily_lists_schedule)
    raise(ArgumentError, 'The daily list schedule can not be updated this way. Please use the schedule generation method.')
  end

  def generate_daily_lists_schedule(time = Date.today.to_time)
    time = Time.at((time.to_f / 1.hour).floor * 1.hour) # make sure time starts on the hour
    schedule = Schedule.new(time, :duration => 3600) # make sure it lasts for an hour
    schedule.add_recurrence_rule Rule.daily # and have it reoccur daily
    self[:daily_lists_schedule] = schedule.to_hash
  end

  def auto_delivery_schedule
    Schedule.from_hash(self[:auto_delivery_schedule]) if self[:auto_delivery_schedule]
  end

  def auto_delivery_schedule=(auto_delivery_schedule)
    raise(ArgumentError, 'The auto delivery schedule can not be updated this way. Please use the schedule generation method.')
  end

  def generate_auto_delivery_schedule(time = Date.tomorrow.to_time)
    time = Time.at((time.to_f / 1.hour).floor * 1.hour) # make sure time starts on the hour
    schedule = Schedule.new(time, :duration => 3600) # make sure it lasts for an hour
    schedule.add_recurrence_rule Rule.daily # and have it reoccur daily
    self[:auto_delivery_schedule] = schedule.to_hash
  end

  def self.create_daily_lists(time = Time.now)
    all.each do |distributor|
      distributor.create_daily_lists(time.to_date) if distributor.daily_lists_schedule.occurring_at?(time)
    end
  end

  def create_daily_lists(date = Date.today)
    PackingList.generate_list(self, date)
    DeliveryList.generate_list(self, date)
  end

  def self.automate_delivered_status(time = Time.now)
    all.each do |distributor|
      distributor.automate_delivered_status(time.to_date) if distributor.auto_delivery_schedule.occurring_at?(time)
    end
  end

  def automate_delivered_status(date = Date.today)
    delivery_lists.find_by_date(date).mark_all_as_auto_delivered
  end

  private

  def parameterize_name
    self.parameter_name = name.parameterize if name
  end

  private
  def downcase_email
    self.email.downcase! if self.email
  end
end
