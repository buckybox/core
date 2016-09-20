# Bucky Box

## AWS Setup

1. Create new EC2 instance
1. Look up for latest Debian stable AMI
1. Select t2.medium (need 4+ GB of RAM)
1. Add 32+ GB of storage
1. Attach security group with TCP 22, 80 & 443 open
1. Launch instance
1. Attach Elastic IP to instance

1. ssh -i ~/.ssh/aws-buckybox-ced admin@52.208.137.102
1. Add host in ~/.ssh/config
1. ssh buckybox-staging-core
1. sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove --purge && sudo reboot
1. echo "127.0.0.1      staging-core" | sudo tee -a /etc/hosts
1. sudo hostnamectl set-hostname staging-core # sudo apt-get install dbus # if missing
1. sudo reboot
1. wget https://raw.githubusercontent.com/infertux/ruby-bootstrap/master/bootstrap_ruby_2.2.sh && chmod +x ./bootstrap_ruby_2.2.sh && sudo ./bootstrap_ruby_2.2.sh
1. sudo apt-get install bzip2 # for ./deploy.sh step below
1. sudo reboot

1. cd chef-repo && ./deploy.sh buckybox-staging-core nodes/staging-core.json
1. When you get "Starting unicorn-core (via systemctl): unicorn-core.service failed!", it's time to import the DB and uploads:
1. Check current minute is NOT close to zero since cron tasks run then
1. Put current site in maintenance mode
1. cd core && cat ./bin/production_to_staging.sh
1. ./bin/production_to_staging.sh
1. cd chef-repo && ./deploy.sh buckybox-staging-core nodes/staging-core.json
1. reboot

1. Set up DNS
1. https://staging-my.buckybox.com/admins/sign_in
1. Grab a beer

## Sign Up Wizard

Here's what you need to do to use the wizard locally:

1. `RAILS_ENV=development bundle exec rake assets:precompile`
1. copy `wizard-localhost.html` to your `/public/` dir
1. `rails s`
1. goto http://buckybox.local:3000/wizard-localhost.html

And when you're done: `RAILS_ENV=development bundle exec rake assets:clean`.

_wizard-localhost.html_:

```html
<html>
<head>
<title>Test</title>
<style>
p { font-size: 100px; }
</style>
</head>

<body>
<h1>My test website!</h1>

<button onclick="_bucky_box_sign_up_wizard.push(['show']);">Show</button>

<p>blah blah blah blah blah blah...</p>
<p>blah blah blah blah blah blah...</p>

<script type="text/javascript" src="https://code.jquery.com/jquery-1.9.1.js"></script>
<script type="text/javascript" src="http://buckybox.local:3000/assets/sign_up_wizard.js" async="true"></script>
<script type="text/javascript">
  var _bucky_box_sign_up_wizard = _bucky_box_sign_up_wizard || [];
  _bucky_box_sign_up_wizard.push(["setHost", "http://buckybox.local:3000"]);
  _bucky_box_sign_up_wizard.push(["show"]);
</script>
</body>
</html>
```
