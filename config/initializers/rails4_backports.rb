class ActiveRecord::Base
  raise "#find_by already implemented" if respond_to? :find_by
  class << self
    def find_by(*args)
      where(*args).first
    end
  end
end
