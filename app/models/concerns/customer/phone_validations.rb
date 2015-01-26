require 'active_support/concern'

module Customer::PhoneValidations

  extend ActiveSupport::Concern

  included do
    attribute :mobile_phone
    attribute :home_phone
    attribute :work_phone

    validate :validate_phone

  private

    def validate_phone
      if distributor.require_phone && PhoneCollection.attributes.all? { |type| self[type].blank? }
        errors[:phone_number] << "can't be blank"
      end
    end
  end
end

