package :htop do
  description 'Htop'
  apt "htop"
  
  verify do
    has_file '/usr/bin/htop'
  end
end

