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
