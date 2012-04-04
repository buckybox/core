class OrderExtra < ActiveRecord::Base
  belongs_to :order
  belongs_to :extra
end
