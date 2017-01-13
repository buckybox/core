# Bucky Box

## Deployment (using AWS)

1. Create new EC2 instance
1. Look up for latest Debian stable AMI
1. Select t2.medium (need 4+ GB of RAM or 2 GB with swap for small installations)
1. Add 16+ GB of storage
1. Attach security group with TCP 22 & 80 open
1. Launch instance

1. ssh -i ~/.ssh/aws-key admin@IP
1. Add host in ~/.ssh/config
1. ssh buckybox-core
1. sudo apt-get update && sudo apt-get dist-upgrade && sudo apt-get autoremove --purge && sudo reboot
1. echo "127.0.0.1      buckybox-core" | sudo tee -a /etc/hosts
1. sudo hostnamectl set-hostname buckybox-core # sudo apt-get install dbus # if missing
1. sudo reboot
1. wget https://raw.githubusercontent.com/infertux/ruby-bootstrap/master/bootstrap_ruby_2.3.sh && chmod +x ./bootstrap_ruby_2.3.sh && sudo ./bootstrap_ruby_2.3.sh
1. sudo apt-get install bzip2 # for ./deploy.sh step below
1. sudo reboot

1. Set up RDS with Postgresql
1. Allow EC2 instance to access RDS in security group
1. Deploy the Rails app and set up Delayed Job
1. bundle exec rake db:setup

1. Set up DNS
1. https://your-url.net/distributor
1. Log in with demo@example.net and "changeme" as the password

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
