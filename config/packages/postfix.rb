package :postfix do
  description 'postfix mail server'
  apt "postfix"
  
  verify do
    has_executable 'postfix'
    has_file '/etc/init.d/postfix'
  end
end

