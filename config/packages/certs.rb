package :gpg do
  apt :gnupg

  verify do
    has_apt :gnupg
  end
end

package :certs do
  requires :gpg
  
  certs_local = File.join(File.dirname(__FILE__), 'configs', 'certs', Package.stage == 'production' ? 'production' : 'staging', 'certs.tar.gzip.gpg')
  certs_remote = "/etc/ssl/certs/"
  tmp_file = "/tmp/certs.tar.gzip.gpg"
  key_name = Package.stage == 'production' ? 'my_buckybox_com' : 'staging_buckybox_com'

  transfer certs_local, tmp_file do
    post :install, "mv #{tmp_file} #{certs_remote}"
    post :install, lambda {%(expect -c "set my_password \"#{Capistrano::CLI.ui.ask("SSL Certs password: ").gsub(/\(/, '\(').gsub(/\)/,'\)')}\";spawn gpg certs.tar.gzip.gpg;expect \"Enter passphrase:\" {;send \"\$my_password\r\";  expect eof}")}
    post :install, "tar -zxf #{certs_remote}certs.tar.gzip"
    post :install, "cp #{key_name}.key /etc/ssl/private/"
  end

end
