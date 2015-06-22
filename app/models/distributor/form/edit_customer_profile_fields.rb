require 'active_support/concern'
require_relative "../form"

module Distributor::Form::EditCustomerProfileFields
  extend ActiveSupport::Concern
  include Distributor::Form
  include Customer::PhoneValidations

  included do
    attribute :number,                    Integer
    attribute :first_name,                String
    attribute :last_name,                 String
    attribute :tag_list,                  String
    attribute :email,                     String
    attribute :balance_threshold,         Float,   default: ->(obj, _attr) { obj.customer.balance_threshold }
    attribute :discount,                  Float,   default: ->(obj, _attr) { obj.customer.discount }
    attribute :special_order_preference,  String

    delegate :require_phone?, :collect_phone?, :has_balance_threshold?, to: :distributor

    validates_presence_of :first_name
    validates_presence_of :email
    validates_presence_of :discount

    def auto_assign_number?
      customer.new_record?
    end

  protected

    def assign_attributes(attributes)
      @number                   = attributes["number"] || customer.number
      @first_name               = attributes["first_name"] || customer.first_name
      @last_name                = attributes["last_name"] || customer.last_name
      @tag_list                 = attributes["tag_list"] || customer.tag_list
      @email                    = attributes["email"] || customer.email
      @balance_threshold        = attributes["balance_threshold"] || customer.balance_threshold
      @discount                 = attributes["discount"] || customer.discount
      @special_order_preference = attributes["special_order_preference"] || customer.special_order_preference
      @mobile_phone             = attributes["mobile_phone"] || address.mobile_phone
      @home_phone               = attributes["home_phone"] || address.home_phone
      @work_phone               = attributes["work_phone"] || address.work_phone
    end

    def profile_customer_args
      {
        number:                   number,
        first_name:               first_name,
        last_name:                last_name,
        tag_list:                 tag_list,
        email:                    email,
        balance_threshold:        balance_threshold,
        discount:                 discount,
        special_order_preference: special_order_preference,
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
