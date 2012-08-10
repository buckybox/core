package :build_essential do
  describe 'Build tools'

  apt 'build-essential' do
    pre :install, 'apt-get -y update'
  end
  
  verify do
    has_apt 'build-essential'
  end
end
