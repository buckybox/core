package :nokogiri do
  describe 'Nokogiri'

  apt 'libxml2 libxml2-dev libxslt libxslt-dev' do
    pre :install, 'apt-get -y update'
  end
  
  verify do
    has_apt 'libxml2'
    has_apt 'libxml2-dev'
    has_apt 'libxslt-dev'
  end
end
