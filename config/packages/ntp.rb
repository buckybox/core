package :ntp do

  description "NTP client to prevent time skew issues."

  apt "ntp"

  verify do
    has_apt "ntp"
  end

end
