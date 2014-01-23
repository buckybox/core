require 'active_support/concern'
require_relative "../form"

module Distributor::Form::EditCustomerProfileFields

  extend ActiveSupport::Concern
  include Distributor::Form

  included do

    attribute :number,                    Integer
    attribute :name,                      String
    attribute :tag_list,                  String
    attribute :email,                     String
    attribute :mobile_phone,              String
    attribute :home_phone,                String
    attribute :work_phone,                String
    attribute :balance_threshold,         Float,   default: ->(obj, attr) { obj.customer.balance_threshold }
    attribute :discount,                  Float,   default: ->(obj, attr) { obj.customer.discount }
    attribute :special_order_preference,  String

    def_delegators :distributor,
      :require_phone?,
      :collect_phone?,
      :has_balance_threshold?

    validates_presence_of :name
    validates_presence_of :email
    validates_presence_of :discount
    validates_presence_of :mobile_phone,  if: -> { require_phone? }
    validates_presence_of :home_phone,    if: -> { require_phone? }
    validates_presence_of :work_phone,    if: -> { require_phone? }

    def auto_assign_number?
      customer.new_record?
    end

  protected

    def assign_attributes(attributes)
      @number            = attributes["number"]            || customer.number
      @name              = attributes["name"]              || customer.name
      @tag_list          = attributes["tag_list"]          || customer.tag_list
      @email             = attributes["email"]             || customer.email
      @balance_threshold = attributes["balance_threshold"] || customer.balance_threshold
      @discount          = attributes["discount"]          || customer.discount
      @mobile_phone      = attributes["mobile_phone"]      || address.mobile_phone
      @home_phone        = attributes["home_phone"]        || address.home_phone
      @work_phone        = attributes["work_phone"]        || address.work_phone
    end

    def profile_customer_args
      {
        number:             number,
        first_name:         name,
        last_name:          nil,
        tag_list:           tag_list,
        email:              email,
        balance_threshold:  balance_threshold,
        discount:           discount,
      }
    end

    def profile_address_args
      {
        mobile_phone:  mobile_phone,
        home_phone:    home_phone,
        work_phone:    work_phone,
      }
    end

  end

end
