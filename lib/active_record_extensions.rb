module ActiveRecordExtensions
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Like {ActiveModel::Validations#valid?} but allows to validate only a sub-set
  # of attributes.
  # @param options Hash
  #   :except Array attributes to ignore
  #   :only Array only validate these attributes
  #   :context boolean Context to pass to {ActiveModel::Validations#valid?}
  def valid_attributes? options
    valid? options[:context]

    only = options[:only]
    except = options[:except]

    if only && except
      raise ArgumentError, "Cannot use :except and :only at the same time"
    end

    attributes = errors.messages.dup
    attributes.each do |key, message|
      if (except && except.include?(key)) || (only && !only.include?(key))
        attributes.delete(key)
        errors.delete(key)
      end
    end

    attributes.empty?
  end

  module ClassMethods
    # Add class methods here
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtensions)

