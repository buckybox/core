module Distributor::SettingsHelper

  def show_settings_metric(key, value)
    render partial: 'distributor/settings/reporting_item', locals: {key: key, value: value}
  end
end
