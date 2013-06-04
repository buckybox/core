require 'active_model/naming'
require 'active_model/conversion'

class Form
  extend ::ActiveModel::Naming
  include ::ActiveModel::Conversion

  def persisted?
    false
  end
end
