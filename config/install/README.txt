#To create a new production server from scratch follow below:
#
#1.  Create a new server running Ubuntu 12.04 LTS
#2.  Login with root and paste in the following

curl -s https://raw.github.com/gist/48896190a991f8ecc16b/server_setup.sh > s.sh
chmod +x s.sh
./s.sh

#2b.  It will ask for a username and then a password for that user.  It will create iptables from https://gist.github.com/raw/48896190a991f8ecc16b/4083e31473dda834a69dca82afb737df3bce807c/iptables
#2c.  It will change ssh to a random port and lock ssh down so that only Jordan's ssh key will allow login, turns login for root off, turns login via password off.

#3.  Now update config/deploy/#{rails_env} 's domain and port to match the printed values (use the FIRST ip address in the list, the second will be rackspaces internal ip)
#4.  Run:

cap [rails_env] provision:app

#4b.  This will install everything for the app and deploy the code but WILL NOT MOVE THE DB
#5.  You now need to somehow get whatever backup of production's DB you have onto the new machine
#5X  If the old machine is up and running on my.buckybox.com you can try 'cap #{rails_env} provision:copy_old_data' which will copy its DB to the new one.
#6.  You can run 'cap deploy:migrations' once you have done that and everything should be good to go.
