module Distributor::SettingsHelper

  def days_in_advance(n = 7)
    # Makes [['1 day', 1],['2 days', 2],['3 days', 3],...]
    (1..n.to_i).to_a.map { |i| [pluralize(i, 'day'), i] }
  end

end
