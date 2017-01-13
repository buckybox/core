# Bucky Box

## Development (local install)

1. `bundle install`
1. `bundle exec rake db:setup`
1. `bundle exec foreman start`
1. `open http://localhost:3000/distributor`
1. Log in with demo@example.net:changeme

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

## License

See [LICENSE](LICENSE).
