class BoxExtra < ActiveRecord::Base
  belongs_to :box
  belongs_to :extra

  # TODO: Shouldn't there be some validations here?
end
