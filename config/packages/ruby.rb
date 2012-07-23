package :ruby do
  description 'Ruby Virtual Machine'
  version '1.9.3'
  patchlevel '194'
  binaries = %w( ruby rdoc ri rake irb erb )
  source "ftp://ftp.ruby-lang.org/pub/ruby/#{version.split(".")[0..1].join(".")}/ruby-#{version}-p#{patchlevel}.tar.gz" do
    binaries.each {|bin| post :install, "ln -s usr/local/bin/#{bin} /usr/bin/#{bin}"}
  end
  requires :ruby_dependencies
  verify do
    binaries.each {|bin| has_executable bin}
  end
end

package :ruby_dependencies do
  description 'Ruby Virtual Machine Build Dependencies'
  apt %w(bison zlib1g-dev libssl-dev libreadline6-dev libncurses5-dev file libyaml-dev)
  verify do
    has_apt "bison"
    has_apt "zlib1g-dev"
    has_apt "libssl-dev"
    has_apt "libreadline6-dev"
    has_apt "libncurses5-dev"
    has_apt "file"
    has_apt "libyaml-dev"
  end
end

package :rubygems do
  description 'Ruby Gems Package Management System'
  version '1.8.24'
  binaries = %w( gem )
  source "http://production.cf.rubygems.org/rubygems/rubygems-#{version}.tgz" do
    custom_install 'ruby setup.rb'
    binaries.each {|bin| post :install, "ln -s usr/local/bin/#{bin} /usr/bin/#{bin}"}
  end
  requires :ruby
  verify do
    has_executable "gem"
  end
end
