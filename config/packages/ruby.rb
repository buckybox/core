# More info at https://trello.com/c/PiqmBRC2/339-upgrade-to-ruby-2

package :ruby do
  description 'Ruby Virtual Machine'
  version '2.1.0'
  patchlevel '' # e.g. '353' or '' for none
  binaries = %w( ruby rdoc ri rake irb erb )
  source "ftp://ftp.ruby-lang.org/pub/ruby/#{version.split(".")[0..1].join(".")}/ruby-#{version}#{"-p#{patchlevel}" unless patchlevel.empty?}.tar.gz" do
    binaries.each {|bin| post :install, "ln -sf usr/local/bin/#{bin} /usr/bin/#{bin}"}
  end
  requires :ruby_dependencies
  verify do
    binaries.each {|bin| has_executable bin}
  end
end

package :ruby_dependencies do
  description 'Ruby Virtual Machine Build Dependencies'
  apt %w(bison zlib1g-dev libssl-dev libreadline6-dev libncurses5-dev file libyaml-dev libicu-dev)
  verify do
    has_apt "bison"
    has_apt "zlib1g-dev"
    has_apt "libssl-dev"
    has_apt "libreadline6-dev"
    has_apt "libncurses5-dev"
    has_apt "file"
    has_apt "libyaml-dev"
    has_apt "libicu-dev"
  end
end

package :rubygems do
  description 'Ruby Gems Package Management System'
  version '2.1.11'
  binaries = %w( gem )
  source "http://production.cf.rubygems.org/rubygems/rubygems-#{version}.tgz" do
    custom_install 'ruby setup.rb'
    binaries.each {|bin| post :install, "ln -sf usr/local/bin/#{bin} /usr/bin/#{bin}"}
  end
  requires :ruby
  verify do
    has_executable "gem"
  end
end
