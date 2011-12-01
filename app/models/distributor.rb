class Distributor < ActiveRecord::Base
  has_many :boxes
  has_many :routes

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :company_logo, CompanyLogoUploader

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url, :company_logo

  validates_uniqueness_of :email

  validates_presence_of :name, :on => :update
  validates_uniqueness_of :name, :on => :update
end
