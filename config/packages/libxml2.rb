package :libxml2 do
  describe 'Nokogiri requirement'

  apt 'libxml2 libxml2-dev' do
    pre :install, 'apt-get -y update'
  end
  
  verify do
    has_apt 'libxml2'
    has_apt 'libxml2-dev'
  end
end
