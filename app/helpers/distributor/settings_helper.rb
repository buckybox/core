module Distributor::SettingsHelper
  def days_in_advance
    # Makes [['1 day', 1],['2 days', 2],['3 days', 3],...]
    (1..Distributor::MAX_ADVANCED_DAYS).to_a.map { |i| [pluralize(i, 'day'), i] }
  end
end
