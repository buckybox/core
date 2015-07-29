class ActiveRecord::Base
  raise "#find_by already implemented, have we upgraded to Rails 4???" if respond_to? :find_by

  class << self
    def find_by(*args)
      where(*args).first
    end

    def none
      where("1=0")
    end
  end
end

module AbstractController::Callbacks::ClassMethods
  alias_method :before_action, :before_filter
  alias_method :skip_before_action, :skip_before_filter
  alias_method :skip_after_action, :skip_after_filter
end

class ActiveRecord::Associations::HasManyAssociation
  def has_cached_counter?(*)
    false
  end
end
