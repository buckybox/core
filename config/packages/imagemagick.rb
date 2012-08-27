package :imagemagick do
  description 'imagemagick'
  apt "imagemagick"
  
  verify do
    has_file '/usr/bin/identify'
  end
end
