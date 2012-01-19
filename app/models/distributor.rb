class Distributor < ActiveRecord::Base
  has_one :bank_information, :dependent => :destroy
  has_one :invoice_information, :dependent => :destroy

  has_many :boxes,        :dependent => :destroy
  has_many :routes,       :dependent => :destroy
  has_many :orders,       :dependent => :destroy, :through => :boxes
  has_many :deliveries,   :dependent => :destroy, :through => :orders
  has_many :payments,     :dependent => :destroy
  has_many :customers
  has_many :accounts,     :dependent => :destroy, :through => :customers
  has_many :transactions, :dependent => :destroy, :through => :accounts
  has_many :events

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

  def parameterize_name
    self.parameter_name = name.parameterize if name
  end

  private
  def downcase_email
    self.email.downcase! if self.email
  end
end
