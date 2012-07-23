package :nodejs do
  description 'Node js'
  version '0.6.19'
  binaries = %w( node )
  source "http://nodejs.org/dist/v#{version}/node-v#{version}.tar.gz" do
    binaries.each {|bin| post :install, "ln -s usr/local/bin/#{bin} /usr/bin/#{bin}"}
  end
  verify do
    binaries.each {|bin| has_executable bin}
  end
end
