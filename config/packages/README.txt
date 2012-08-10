Welcome to sprinkles packages.

This is a bunch of files describing how to install a new server.

More information:
https://github.com/crafterm/sprinkle
https://github.com/blahutka/sprinkle_packages/tree/master/lib/sprinkle_packages/packages
http://maxim.github.com/sprinkle-cheatsheet/
https://github.com/trevorturk/sprinkle-packages

The current setup has relied on the fact the destination server has been setup to have a user with sudo and it has been hardened (ports locked down, ssh setup securely)

A gist used to setup the new servers: https://gist.github.com/48896190a991f8ecc16b (make sure to actually read it and put your shit where your shit needs to be put, maybe make a copy and modify it). This step might have been able to be done by sprinkle, but hey, I wrote it in bash.

OH! Checkout ../install.rb also, it combines everything together and deployes a new server.

Run with:
bundle exec sprinkle -v -s config/install.rb
